defmodule Mix.Tasks.Setup do
  use Mix.Task

  @shortdoc "Sets up a new clean-slate project using the phoenix-starter project as a base template"

  @doc """
  This function runs several other functions: 
    - rename_app(name, otp_name): rename the app (using the provided 'name' and 'otp_name' params)
    - remove_rename_dependency(): Remove the rename module (since it will no longer be needed in the new project being created)
    - Remove the mix task (this module)
    - Remove

  # NOTE: Should we run yarn install in this list of tasks? or have users do it separately from the command line as a docker-compose command (note that users will be instructed to run the mix setup task within a Docker container)
  
  """
  def run([name, otp_name]) do
    with :ok <- rename_app(name, otp_name),
         :ok <- remove_rename_dependency(),
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
end