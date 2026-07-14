// amonite tui — derivation hierarchy viewer.
//
// Reads the project's `graph.<system>` flake output, renders the
// task→cluster→APP tree with verified/pending state (a node is verified
// iff its store path exists), and lets you verify nodes in place.
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

type model struct {
	rows     []row
	cursor   int
	building bool
	status   string
	err      string
}

type graphMsg struct {
	rows []row
	err  error
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
		return graphMsg{err: fmt.Errorf("nix eval failed: %s", lastLine(detail))}
	}
	var g graph
	if err := json.Unmarshal(out, &g); err != nil {
		return graphMsg{err: err}
	}
	return graphMsg{rows: layout(g)}
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
		if msg.err != nil {
			m.err = msg.err.Error()
		} else {
			m.err = ""
			m.rows = msg.rows
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
)

func (m model) View() string {
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

	if len(m.rows) == 0 && m.err == "" {
		b.WriteString(pendingStyle.Render("loading graph…") + "\n")
	}

	b.WriteString("\n")
	if m.status != "" {
		b.WriteString(m.status + "\n")
	}
	b.WriteString(helpStyle.Render("↑/↓ move · enter verify · r refresh · q quit") + "\n")
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
		m := model{rows: gm.rows}
		fmt.Print(m.View())
		return
	}

	if _, err := tea.NewProgram(model{}).Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
