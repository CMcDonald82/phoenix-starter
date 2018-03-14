defmodule SetupTest do
  use ExUnit.Case, async: false

  @app_dir "phoenix_starter_test_app"
  @app_name "PhoenixStarterTestApp"
  @git_repo "https://github.com/CMcDonald82/phoenix-starter.git"


  # NOTE: Instead of curl'ing localhost (which doesn't seem to work in a docker container in travis test), why don't we just test that the layout template (lib/phoenix_starter_web/templates/layout contains Hello #{@app_name}!
  @tag timeout: :infinity
  test "sets up app with passed in app name params" do
    File.cd!("..")
    :os.cmd('rm -rf #{@app_dir}')
    git_clone_starter()
    File.cd!(@app_dir)
    :os.cmd('mix deps.get')
    # :os.cmd('mix compile')
    :os.cmd('mix setup #{@app_name} #{@app_dir}')
    refute File.exists?("lib/mix/tasks/setup.ex")
    assert check_app_renamed()
    # start_server()
    # :timer.sleep(10000)
    # :os.cmd('curl http://localhost:4000')
    # {page, 0} = System.cmd("curl", ["localhost:4000"])
    # assert page |> String.contains?("Hello #{@app_name}!")
    # kill_server()
  end

  defp git_clone_starter do
    :os.cmd('git clone #{@git_repo} #{@app_dir}')
    :os.cmd('git fetch')
    :os.cmd('git branch')
    :os.cmd('git checkout add_setup_task')
  end

  defp check_app_renamed do
    File.read!("mix.exs")
    |> String.split("\n")
    |> IO.inspect
    |> Enum.member?(@app_name)
  end


  # defp start_server do
  #   spawn fn ->
  #     :os.cmd('mix phx.server')
  #   end
  # end

  # defp kill_server do
  #   "ps"
  #   |> System.cmd(["-ef"])
  #   |> elem(0)
  #   |> String.split("\n")
  #   |> Enum.filter(&(&1 |> String.contains?("mix phx.server")))
  #   |> Enum.each(fn process ->
  #     pid = process
  #     |> String.split(" ")
  #     |> Enum.reject(&(&1 == ""))
  #     |> Enum.at(1)
  #     :os.cmd('kill -9 #{pid}')
  #   end)
  # end

end