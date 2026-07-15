// amonite tui — derivation hierarchy viewer + wave view.
//
// Reads the project's `graph.<system>` flake output, renders the
// task→cluster→APP tree with verified/pending state (a node is verified
// iff its store path exists), and lets you verify nodes in place.
//
// Press "w" to toggle the wave view which reads .amonite/task-graph.json
// and groups tasks by wave number with live verification state.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"sort"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type node struct {
	ID      string   `json:"id"`
	Title   string   `json:"title"`
	Kind    string   `json:"kind"`
	Store   string   `json:"store"`
	Members []string `json:"members"`
}

type graph struct {
	Nodes []node `json:"nodes"`
}

// row is one visible line: a node at a depth in the hierarchy.
type row struct {
	node   node
	depth  int
	last   bool   // last child of its parent (tree glyph choice)
	indent string // precomputed ancestor continuation prefix
}

// waveTask is one task entry from task-graph.json.
type waveTask struct {
	ID      string   `json:"id"`
	Title   string   `json:"title"`
	Cluster string   `json:"cluster"`
	Depends []string `json:"depends"`
}

// waveEntry is one wave from task-graph.json.
type waveEntry struct {
	Wave  int        `json:"wave"`
	Tasks []waveTask `json:"tasks"`
}

// waveGraph is the top-level structure of .amonite/task-graph.json.
type waveGraph struct {
	Waves []waveEntry `json:"waves"`
}

// viewMode selects which view is active.
type viewMode int

const (
	viewTree viewMode = iota
	viewWave
)

type model struct {
	rows      []row
	cursor    int
	building  bool
	status    string
	err       string
	noGraph   bool
	mode      viewMode
	waveGraph *waveGraph        // nil if task-graph.json absent or unreadable
	storeByID map[string]string // task ID → store path (from nix graph)
}

type graphMsg struct {
	rows      []row
	storeByID map[string]string
	err       error
	noGraph   bool
}

type buildDoneMsg struct {
	id  string
	err error
}

func nixSystem() string {
	arch := map[string]string{"amd64": "x86_64", "arm64": "aarch64"}[runtime.GOARCH]
	return fmt.Sprintf("%s-%s", arch, runtime.GOOS)
}

func loadGraph() tea.Msg {
	out, err := exec.Command("nix", "eval", "--json",
		fmt.Sprintf(".#graph.%s", nixSystem())).Output()
	if err != nil {
		detail := err.Error()
		var ee *exec.ExitError
		if ok := asExitError(err, &ee); ok {
			detail = strings.TrimSpace(string(ee.Stderr))
		}
		// Friendly message when the project hasn't defined a graph output yet.
		if strings.Contains(detail, "attribute 'graph' missing") ||
			strings.Contains(detail, "does not provide attribute") {
			return graphMsg{noGraph: true}
		}
		return graphMsg{err: fmt.Errorf("nix eval failed: %s", lastLine(detail))}
	}
	var g graph
	if err := json.Unmarshal(out, &g); err != nil {
		return graphMsg{err: err}
	}
	// Build store lookup by task ID for wave view cross-referencing.
	storeByID := map[string]string{}
	for _, n := range g.Nodes {
		if n.Store != "" {
			storeByID[n.ID] = n.Store
		}
	}
	return graphMsg{rows: layout(g), storeByID: storeByID}
}

// loadWaveGraph reads .amonite/task-graph.json and returns parsed data or nil.
func loadWaveGraph() *waveGraph {
	data, err := os.ReadFile(".amonite/task-graph.json")
	if err != nil {
		return nil
	}
	var wg waveGraph
	if err := json.Unmarshal(data, &wg); err != nil {
		return nil
	}
	return &wg
}

func asExitError(err error, target **exec.ExitError) bool {
	ee, ok := err.(*exec.ExitError)
	if ok {
		*target = ee
	}
	return ok
}

func lastLine(s string) string {
	lines := strings.Split(strings.TrimSpace(s), "\n")
	return lines[len(lines)-1]
}

// layout flattens the graph into tree rows: roots (nodes nobody lists as
// a member) first, members indented beneath their parent.
func layout(g graph) []row {
	byID := map[string]node{}
	isMember := map[string]bool{}
	for _, n := range g.Nodes {
		byID[n.ID] = n
		for _, m := range n.Members {
			isMember[m] = true
		}
	}

	var roots []node
	for _, n := range g.Nodes {
		if !isMember[n.ID] {
			roots = append(roots, n)
		}
	}
	// APP first, then clusters, then tasks, alphabetical within.
	rank := func(n node) string {
		r := "2"
		if n.ID == "APP" {
			r = "0"
		} else if n.Kind == "cluster" {
			r = "1"
		}
		return r + n.ID
	}
	sort.Slice(roots, func(i, j int) bool { return rank(roots[i]) < rank(roots[j]) })

	var rows []row
	var walk func(n node, depth int, last bool, indent string)
	walk = func(n node, depth int, last bool, indent string) {
		rows = append(rows, row{node: n, depth: depth, last: last, indent: indent})
		childIndent := indent
		if depth > 0 {
			if last {
				childIndent += "   "
			} else {
				childIndent += "│  "
			}
		}
		for i, id := range n.Members {
			child, ok := byID[id]
			if !ok { // member without a node entry (shouldn't happen)
				child = node{ID: id, Title: "(unknown)", Kind: "task"}
			}
			walk(child, depth+1, i == len(n.Members)-1, childIndent)
		}
	}
	for i, r := range roots {
		walk(r, 0, i == len(roots)-1, "")
	}
	return rows
}

func verified(n node) bool {
	if n.Store == "" {
		return false
	}
	_, err := os.Stat(n.Store)
	return err == nil
}

// statePath checks whether a Nix store path exists on disk.
func statePath(storePath string) bool {
	if storePath == "" {
		return false
	}
	_, err := os.Stat(storePath)
	return err == nil
}

func (m model) buildCmd(target string) tea.Cmd {
	return func() tea.Msg {
		attr := ".#task-" + target
		if target == "APP" {
			attr = ".#default"
		} else if strings.HasPrefix(target, "C") || isCluster(m.rows, target) {
			attr = ".#cluster-" + target
		}
		out, err := exec.Command("nix", "build", "--no-link", attr).CombinedOutput()
		if err != nil {
			return buildDoneMsg{id: target, err: fmt.Errorf("%s", lastLine(string(out)))}
		}
		return buildDoneMsg{id: target}
	}
}

func isCluster(rows []row, id string) bool {
	for _, r := range rows {
		if r.node.ID == id {
			return r.node.Kind == "cluster"
		}
	}
	return false
}

func (m model) Init() tea.Cmd { return loadGraph }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case graphMsg:
		if msg.noGraph {
			m.noGraph = true
			m.err = ""
		} else if msg.err != nil {
			m.err = msg.err.Error()
		} else {
			m.noGraph = false
			m.err = ""
			m.rows = msg.rows
			if msg.storeByID != nil {
				m.storeByID = msg.storeByID
			}
			if m.cursor >= len(m.rows) {
				m.cursor = 0
			}
		}
		return m, nil

	case buildDoneMsg:
		m.building = false
		if msg.err != nil {
			m.status = fmt.Sprintf("✗ %s failed: %s", msg.id, msg.err)
		} else {
			m.status = fmt.Sprintf("✓ %s verified", msg.id)
		}
		return m, loadGraph

	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.rows)-1 {
				m.cursor++
			}
		case "r":
			m.status = "refreshing…"
			return m, loadGraph
		case "w":
			// Toggle between tree and wave view; load task-graph.json on switch.
			if m.mode == viewTree {
				m.mode = viewWave
				m.waveGraph = loadWaveGraph()
			} else {
				m.mode = viewTree
			}
		case "enter", "v":
			if m.building || len(m.rows) == 0 {
				return m, nil
			}
			id := m.rows[m.cursor].node.ID
			m.building = true
			m.status = fmt.Sprintf("building %s…", id)
			return m, m.buildCmd(id)
		}
	}
	return m, nil
}

var (
	okStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	pendingStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	kindStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("4"))
	cursorStyle  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("5"))
	titleStyle   = lipgloss.NewStyle().Bold(true)
	errStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("1"))
	helpStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	waveStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("3"))
)

func (m model) waveView() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("amonite — wave view") + "\n\n")

	if m.waveGraph == nil {
		b.WriteString(errStyle.Render("no task-graph.json — run /amonite.plan first") + "\n")
	} else {
		for _, we := range m.waveGraph.Waves {
			b.WriteString(waveStyle.Render(fmt.Sprintf("Wave %d (%d tasks)", we.Wave, len(we.Tasks))) + "\n")
			for _, t := range we.Tasks {
				storePath := m.storeByID[t.ID]
				mark := pendingStyle.Render("○")
				if statePath(storePath) {
					mark = okStyle.Render("●")
				}
				line := fmt.Sprintf("  %s %s  %s  %s",
					mark,
					kindStyle.Render(t.ID),
					pendingStyle.Render(t.Cluster),
					t.Title)
				b.WriteString(line + "\n")
			}
		}
	}

	b.WriteString("\n")
	if m.status != "" {
		b.WriteString(m.status + "\n")
	}
	b.WriteString(helpStyle.Render("w tree view · r refresh · q quit") + "\n")
	return b.String()
}

func (m model) View() string {
	if m.mode == viewWave {
		return m.waveView()
	}

	var b strings.Builder
	b.WriteString(titleStyle.Render("amonite — derivation hierarchy") + "\n\n")

	if m.err != "" {
		b.WriteString(errStyle.Render(m.err) + "\n")
	}

	for i, r := range m.rows {
		glyph := "├─"
		if r.last {
			glyph = "└─"
		}
		prefix := ""
		if r.depth > 0 {
			prefix = r.indent + glyph + " "
		}

		mark := pendingStyle.Render("○")
		if verified(r.node) {
			mark = okStyle.Render("●")
		}

		line := fmt.Sprintf("%s%s %s %s %s",
			prefix, mark,
			kindStyle.Render("["+r.node.Kind+"]"),
			r.node.ID,
			pendingStyle.Render("· "+r.node.Title))

		if i == m.cursor {
			line = cursorStyle.Render("▸ ") + line
		} else {
			line = "  " + line
		}
		b.WriteString(line + "\n")
	}

	if m.noGraph {
		b.WriteString(pendingStyle.Render("no graph yet") + "\n")
		b.WriteString(helpStyle.Render("run /amonite.plan → /amonite.tasks to generate the derivation hierarchy") + "\n")
	} else if len(m.rows) == 0 && m.err == "" {
		b.WriteString(pendingStyle.Render("loading graph…") + "\n")
	}

	b.WriteString("\n")
	if m.status != "" {
		b.WriteString(m.status + "\n")
	}
	b.WriteString(helpStyle.Render("↑/↓ move · enter verify · r refresh · w wave view · q quit") + "\n")
	return b.String()
}

func main() {
	// --dump: headless render for CI / smoke tests.
	if len(os.Args) > 1 && os.Args[1] == "--dump" {
		msg := loadGraph()
		gm, _ := msg.(graphMsg)
		if gm.err != nil {
			fmt.Fprintln(os.Stderr, gm.err)
			os.Exit(1)
		}
		m := model{rows: gm.rows, storeByID: gm.storeByID}
		fmt.Print(m.View())
		return
	}

	if _, err := tea.NewProgram(model{}).Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
