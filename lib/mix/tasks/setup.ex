defmodule Mix.Tasks.Setup do
  use Mix.Task

  @shortdoc "Sets up a new clean-slate project using the phoenix-starter project as a base template"

  @doc """
  The main function that runs all the necessary functions to setup the new app from the phoenix-starter project  

  # NOTE: Should we run yarn install in this list of tasks? or have users do it separately from the command line as a docker-compose command (note that users will be instructed to run the mix setup task within a Docker container)
  
  """
  def run([name, otp_name]) do
    with :ok <- rename_app(name, otp_name),
         :ok <- remove_rename_dep(),
         # :ok <- yarn_init() # Run yarn install here?
         :ok <- remove_mix_task(),
         :ok <- remove_setup_config(),
         :ok <- remove_setup_test(),
         :ok <- remove_travis_yml(), # Do we need this? Or just keep the travis file that we already have?
         :ok <- create_readme(),
         :ok <- git_init() do  
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
      config()[:name]
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
  defp remove_rename_dep do
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
  defp remove_mix_task do
    Mix.Shell.IO.info "Removing this mix task (since it is no longer needed once the new project has been setup)"
    Mix.Shell.IO.cmd("rm -rf lib/mix/tasks/setup.ex")
    :ok
  rescue
    _ -> {:error, "Failed to remove mix task"}
  end

  @doc """
  Removes the setup config file since we don't need it anymore once the new project is configured
  The setup config file is imported in config/dev.exs
  """
  defp remove_setup_config do
    Mix.Shell.IO.info "Removing setup config file"
    Mix.Shell.IO.cmd("rm -rf config/setup.exs")
    with_import_config_removed = "config/dev.exs"
    |> File.read!
    |> String.split("\n")
    |> Enum.reject(&(&1 |> String.contains?("setup.exs")))
    |> Enum.join("\n")
    File.write!("config/dev.exs", with_import_config_removed)
  rescue
    _ -> {:error, "Failed to remove setup config import"}
  end

  
end