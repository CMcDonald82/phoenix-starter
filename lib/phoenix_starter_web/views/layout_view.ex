defmodule PhoenixStarterWeb.LayoutView do
  use PhoenixStarterWeb, :view

  def js_script_tag do
    if Application.get_env(:phoenix_starter, :environment) == :prod do
      ~s(<script src="/js/app.js"></script>)
    else
      ~s(<script src="http://0.0.0.0:8080/js/app.js"></script>)
    end 
  end

  def css_link_tag do
    if Application.get_env(:phoenix_starter, :environment) == :prod do
      ~s(<link rel="stylesheet" type="text/css" href="/css/app.css" media="screen,projection" />)
    else
      ""
    end
  end

end
