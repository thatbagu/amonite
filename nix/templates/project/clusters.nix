# Cluster layer: composition of verified tasks into higher abstractions.
# Filled in by /amonite.tasks after decomposition; grows as tasks verify.
#
# The cluster named APP is the final derivation aka the working application
# (exposed as packages.default).
{ pkgs, tasks, amonite }:

{
  # Example shape (uncomment and adapt once tasks exist):
  #
  # foundation = amonite.mkCluster {
  #   id = "C001";
  #   title = "Foundation: models + config";
  #   tasks = [ tasks.T001 tasks.T002 ];
  #   verify = {
  #     schema-loads = ''test -e "$out/tasks/T001/schema.sql"'';
  #   };
  # };
  #
  # Integration in a real VM (Linux builders only): a vm-verify is an
  # ordinary derivation, so listing it as a cluster member makes the
  # cluster unbuildable until the VM test passes.
  #
  # api-in-vm = amonite.mkVmVerify {
  #   id = "V001";
  #   nodes.machine = { pkgs, ... }: { systemd.services.api = { ... }; };
  #   testScript = ''
  #     machine.wait_for_unit("api.service")
  #     machine.succeed("curl -sf http://localhost:8080/health")
  #   '';
  # };
  #
  # APP = amonite.mkApplication {
  #   id = "APP";
  #   title = "Final application";
  #   tasks = [ foundation ];
  #   integrate = ''
  #     mkdir -p "$out/bin"
  #     # assemble the deliverable from member outputs
  #   '';
  #   verify = {
  #     smoke = ''"$out/bin/app" --version'';
  #   };
  # };
}
