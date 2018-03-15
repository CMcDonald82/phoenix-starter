defmodule SetupTest do
  use ExUnit.Case, async: false

  @app_dir "phoenix_starter_test_app"
  @app_name "PhoenixStarterTestApp"
  @git_repo "https://github.com/CMcDonald82/phoenix-starter.git"

  setup_all do
    File.cd!("..")
    :os.cmd('rm -rf #{@app_dir}')
    git_clone_starter()
    File.cd!(@app_dir)

    git_checkout_branch() # remove when branch is merged into master

    :os.cmd('mix deps.get')
    :ok
  end

  @tag timeout: :infinity
  test "sets up app with passed in app name params" do
    :os.cmd('mix setup #{@app_name} #{@app_dir}')
    assert check_app_renamed()
    refute check_rename_dep_exists()
    assert check_new_travis_file()
    assert check_new_readme_file()
    assert check_git_reinit()
    refute File.exists?("#{@app_dir}/README.tmp.md")
    refute File.exists?("#{@app_dir}/config/setup.exs")
    refute File.exists?("#{@app_dir}/lib/mix/tasks/setup.ex")
    refute File.exists?("#{@app_dir}/test/setup_test.exs")
  end

  defp git_clone_starter do
    :os.cmd('git clone #{@git_repo} #{@app_dir}')
  end

  # NOTE: Can remove these git commands once we merge the add_setup_task branch into master
  defp git_checkout_branch do
    :os.cmd('git fetch')
    :os.cmd('git branch')
    :os.cmd('git checkout add_setup_task')
  end

  defp check_git_reinit do
    email = :os.cmd('git config user.email')
    IO.inspect(email)
  end

  defp check_app_renamed do
    read_file_lines("mix.exs")
    |> Enum.any?(&(&1 |> String.contains?(@app_name)))
  end

  defp check_rename_dep_exists do
    read_file_lines("mix.exs")
    |> Enum.any?(&(&1 |> String.contains?(":rename")))
  end

  defp check_new_travis_file do
    read_file_lines(".travis.yml")
    |> Enum.any?(&(&1 |> String.contains?("test yarn")))
  end

  defp check_new_readme_file do
    read_file_lines("README.md")
    |> Enum.any?(&(&1 |> String.contains?(@app_name)))
  end

  defp read_file_lines(path) do
    File.read!(path)
    |> String.split("\n")
  end

end