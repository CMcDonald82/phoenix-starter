defmodule Mix.Tasks.ErlangCookie do
  use Mix.Task

  @shortdoc "Creates an Erlang cookie and outputs the value to a file"

  @moduledoc """
  This task takes a string input on the command line and transforms it into a value suitable to be used as a "magic cookie"
  for the Erlang node (see the "Security" section at http://erlang.org/doc/reference_manual/distributed.html)

  Once the cookie has been created from the string passed in, the cookie will be output to a file .erlang_cookie within
  the top-level directory of this project. 

  The cookie created by this task (it should be in the .erlang_cookie file) should then be exported as an environment 
  variable called ERLANG_COOKIE both locally and on the remote server.
  """

  @doc """
  This function runs the task
  """
  def run([]) do
    with :ok <- create_erlang_cookie() do
      :ok
    end
    |> case do
      :ok -> print_conclusion_message()
      {:error, error} -> print_error_message(error)
    end       
  end

  @doc """
  This run function handles all other cases
  """
  def run(_) do
    """
    This task should be run with no args:
    mix erlang_cookie
    """
    |> print_error_message
  end

  def create_erlang_cookie do
    cookie = :crypto.hash(:sha256, :crypto.strong_rand_bytes(25))
    |> Base.encode16
    
    File.write!(".erlang_cookie", cookie)
    :ok
  rescue
    _ -> {:error, "Failed to create erlang magic cookie"}
  end

  defp print_conclusion_message do
    Mix.Shell.IO.info """
    Erlang magic cookie successfully created!

    Check the .erlang_cookie file
    Copy the cookie in that file and export the environment variable ERLANG_COOKIE on the remote host.

    export ERLANG_COOKIE=<value copied from .erlang_cookie file>
    """
  end

  defp print_error_message(error) do
    Mix.Shell.IO.error(error)
  end

end