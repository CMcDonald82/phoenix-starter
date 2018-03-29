defmodule Mix.Tasks.Setup do
  use Mix.Task

  @shortdoc "Sets up a new clean-slate project using the phoenix-starter project as a base template"

  @doc """
  The main function that runs all the necessary functions to setup the new app from the phoenix-starter project 
  """
  def run([name, otp_name]) do
    with :ok <- rename_app(name, otp_name),
         :ok <- remove_rename_dep(),
         :ok <- create_new_readme(),
         :ok <- remove_readme_template(),
         :ok <- remove_setup_config(),
         :ok <- remove_mix_task(),
         :ok <- remove_setup_test(),
         :ok <- git_reinit() do  
      :ok
    end
    |> case do
      :ok -> print_conclusion_message()
      {:error, error} -> print_error_message(error)
    end
  end

  @doc """
  The run/1 function will just use the default values for 'name' and 'otp_name' if no values are explicitly passed in.
  These default values will be located in the setup config (located in /config/setup.exs) 
  """
  def run([]) do
    run([
      config()[:name],
      config()[:otp_name]
    ])
  end

  @doc """
  This run function handles all other cases 
  """
  def run(_) do
    """
    The run/1 function should be called in one of 2 ways
    If passing in name and otp_name:
    mix setup AppName app_name
    If using the name/otp_name in config/setup.exs:
    mix setup
    """
    |> print_error_message
  end

  @doc """
  Gets the setup config located in config/setup.exs
  """
  def config do
    Application.get_env(:phoenix_starter, Mix.Tasks.Setup)
  end

  @doc """
  Renames the app using either the 'name' and 'otp_name' params provided on the command line or the 'name' 
  and 'otp_name' params provided in the setup config at config/setup.exs. 
  """
  def rename_app(name, otp_name) do
    Mix.Shell.IO.info "Renaming app to #{name}/#{otp_name}"
    Rename.run(
      {"PhoenixStarter", name},
      {"phoenix_starter", otp_name}
    )
    :ok
  rescue 
    _ -> {:error, "Failed to rename the app to #{name}/#{otp_name}"}
  end

  @doc """
  Removes the Rename dependency from deps in mix.exs (since it will no longer be needed in the new 
  project being created)
  """
  def remove_rename_dep do
    Mix.Shell.IO.info "Removing rename dependency"

    with_rename_dep_removed = "mix.exs"
    |> File.read!
    |> String.split("\n")
    |> Enum.reject(&(&1 |> String.contains?(":rename")))
    |> Enum.join("\n")

    File.write!("mix.exs", with_rename_dep_removed)
  end

  @doc """
  Removes this task (the mix task) since we don't need it anymore once the new project is configured
  """
  def remove_mix_task do
    Mix.Shell.IO.info "Removing this mix task (since it is no longer needed once the new project has been setup)"
    File.rm!("lib/mix/tasks/setup.ex")
    :ok
  rescue
    _ -> {:error, "Failed to remove mix task"}
  end

  @doc """
  Removes the setup config file since we don't need it anymore once the new project is configured
  The setup config file is imported in config/dev.exs - remove the import statement there as well
  """
  def remove_setup_config do
    Mix.Shell.IO.info "Removing setup config file"
    File.rm!("config/setup.exs")

    with_import_config_removed = "config/dev.exs"
    |> File.read!
    |> String.split("\n")
    |> Enum.reject(&(&1 |> String.contains?("setup.exs")))
    |> Enum.join("\n")

    File.write!("config/dev.exs", with_import_config_removed)
  rescue
    _ -> {:error, "Failed to remove setup config import"}
  end

  @doc """
  Removes the test file for the setup mix task since this test will not need to be run in the newly created project.
  This test is already run as part of this repo so it does not need to be included in the projects that are created
  using this repo as a base. Removing this test helps keep the repo of the newly created project clean.
  """
  def remove_setup_test do
    Mix.Shell.IO.info "Removing setup test file"
    File.rm!("test/setup_test.exs")
    :ok
  rescue
    _ -> {:error, "Failed to remove setup test"}
  end

  @doc """
  This is the new version of create_new_readme which creates a new README file using the name of the new app, then
  writes the contents of the README.new.md file to the new README file (these are basically the instructions on how 
  to run the app (build Docker containers, run commands within them, build/deploy releases, etc))
  """
  def create_new_readme do
    Mix.Shell.IO.info "Creating new README.md file"
    
    header = """
    # #{config()[:name]}
    """
    
    File.open!("README.md", [:write])
    |> IO.write(header)
    |> File.close

    File.stream!("README.tmp.md")
    |> Stream.into(File.stream!("README.md", [:append]))
    |> Stream.run
  end

  @doc """
  Removes README.tmp.md (the template for the new README.md file), since that template is for generating the 
  README file for the new project (done in the create_new_readme/0 function)
  """
  def remove_readme_template do
    Mix.Shell.IO.info "Removing README.tmp.md file"
    File.rm!("README.tmp.md")
    :ok
  rescue
    _ -> {:error, "Failed to remove README.tmp.md"}
  end

  @doc """
  Optionally reinitialize git in the repo of the new project that is created.
  This is useful if you want your new project to be a 'blank slate' that does not include any commits from this
  repo.
  This will be run if the :git_reinit variable is set to true in config/setup.exs
  """
  def git_reinit do
    unless config()[:git_reinit] do
      Mix.Shell.IO.info "Skipping git_reinit"
    else
      Mix.Shell.IO.info "Reinitializing git"
      [
        "rm -rf .git",
        "git init", 
        "git add -A"
      ]
      |> Enum.each(&Mix.Shell.IO.cmd/1)
    end
    :ok
  rescue
    _ -> {:error, "Failed to reinitialize git"}
  end

  defp print_conclusion_message do
    Mix.Shell.IO.info """
    Your app has been setup!
    Check out the instructions for running, building and deploying in the new README.md file
    """
  end

  defp print_error_message(error) do
    Mix.Shell.IO.error(error)
  end

end