defmodule CodeReloader.Plug do
  @moduledoc """
  A plug and module to handle automatic code reloading.

  For each request, the Plug checks and recompiles any of the modules in
  the project using `CodeReloader.Server.reload!/1`.

  ```
  defmodule MyRouter do
    use Plug.Router

    plug CodeReloader.Plug, endpoint: __MODULE__
    
    ...etc...
  end
  ```

  Every request through the router will attempt to kick-off a recomplile
  of the current project, and report failures by rendering an error page
  for the web browser.
  """

  @spec reload!(module) :: {:ok, binary()} | {:error, binary()}
  defdelegate reload!(endpoint), to: CodeReloader.Server

  ## Plug

  @behaviour Plug
  import Plug.Conn
  import Logger

  @style %{
    primary: "#EB532D",
    xx: "0",
    accent: "#a0b0c0",
    text_color: "304050",
    logo: "data:data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/Pg0KPCEtLSBHZW5lcmF0b3I6IEFkb2JlIElsbHVzdHJhdG9yIDE4LjEuMSwgU1ZHIEV4cG9ydCBQbHVnLUluIC4gU1ZHIFZlcnNpb246IDYuMDAgQnVpbGQgMCkgIC0tPg0KPHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJDYXBhXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4Ig0KCSB2aWV3Qm94PSIwIDAgMTcuMjEyIDE3LjIxMiIgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgMTcuMjEyIDE3LjIxMjsiIHhtbDpzcGFjZT0icHJlc2VydmUiPg0KPGc+DQoJPGc+DQoJCTxyZWN0IHg9IjUuNDU2IiB5PSI0LjQwNyIgc3R5bGU9ImZpbGw6IzAzMDEwNDsiIHdpZHRoPSIxLjcxNCIgaGVpZ2h0PSI2LjQ1NCIvPg0KCQk8cmVjdCB4PSIxMC4wMjgiIHk9IjQuNDA3IiBzdHlsZT0iZmlsbDojMDMwMTA0OyIgd2lkdGg9IjEuNzEzIiBoZWlnaHQ9IjYuNDU0Ii8+DQoJCTxwYXRoIHN0eWxlPSJmaWxsOiMwMzAxMDQ7IiBkPSJNMTQuOTM1LDIuMjgxbC0wLjEyOC0wLjE3NkgyLjIzMkwyLjEwNCwyLjI3NmMtNC43MTEsNi4yNTctMC4wNDgsMTIuNTk2LDAsMTIuNjU5bDAuMTI4LDAuMTcyDQoJCQloMTIuNTY3bDAuMTY2LTAuMjE1QzE2LjA5MSwxMy40OSwxOS40MTgsOC40MzUsMTQuOTM1LDIuMjgxeiBNMTQuMzgyLDE0LjI0OUgyLjY2OEMxLjk4MywxMy4yNDMtMS4wOTgsOC4xNTcsMi42NjMsMi45NjJoMTEuNzA2DQoJCQlDMTguMTE3LDguMjczLDE1LjcxLDEyLjU0NSwxNC4zODIsMTQuMjQ5eiIvPg0KCQk8cGF0aCBzdHlsZT0iZmlsbDojMDMwMTA0OyIgZD0iTTguNjcxLDEyLjAxMkg4LjQ1N2MtMC42ODMsMC0xLjIzNywwLjU1NS0xLjIzNywxLjIzN3YwLjU0aDIuNjg4di0wLjU0DQoJCQlDOS45MDcsMTIuNTY3LDkuMzU0LDEyLjAxMiw4LjY3MSwxMi4wMTJ6Ii8+DQoJPC9nPg0KPC9nPg0KPGc+DQo8L2c+DQo8Zz4NCjwvZz4NCjxnPg0KPC9nPg0KPGc+DQo8L2c+DQo8Zz4NCjwvZz4NCjxnPg0KPC9nPg0KPGc+DQo8L2c+DQo8Zz4NCjwvZz4NCjxnPg0KPC9nPg0KPGc+DQo8L2c+DQo8Zz4NCjwvZz4NCjxnPg0KPC9nPg0KPGc+DQo8L2c+DQo8Zz4NCjwvZz4NCjxnPg0KPC9nPg0KPC9zdmc+DQo=",
    monospace_font: "menlo, consolas, monospace"
  }

  @doc """
  API used by Plug to start the code reloader.
  """
  def init(opts), do: Keyword.put_new(opts, :reloader, &CodeReloader.Plug.reload!/1)

  @doc """
  API used by Plug to invoke the code reloader on every request.
  """
  def call(conn, opts) do
    reloader = Keyword.get(opts, :reloader)
    endpoint = Keyword.get(opts, :endpoint)
    do_call(conn, reloader, endpoint)
  end

  defp do_call(conn, _reloader, endpoint) when is_nil(endpoint) do
    Logger.error("CodeReloader: couldn't reload. opts[:endpoint] must be specified when using CodeReloader.Plug.")
    conn
  end
  defp do_call(conn, reloader, endpoint) do
    case reloader.(endpoint) do
      {:ok, output} ->
        conn
      {:error, output} ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(500, template(output))
        |> halt()
    end
  end

  defp template(output) do
    {error, headline} = get_error_details(output)

    """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>CompileError</title>
        <meta name="viewport" content="width=device-width">
        <style>/*! normalize.css v4.2.0 | MIT License | github.com/necolas/normalize.css */html{font-family:sans-serif;line-height:1.15;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0}article,aside,details,figcaption,figure,footer,header,main,menu,nav,section,summary{display:block}audio,canvas,progress,video{display:inline-block}audio:not([controls]){display:none;height:0}progress{vertical-align:baseline}template,[hidden]{display:none}a{background-color:transparent;-webkit-text-decoration-skip:objects}a:active,a:hover{outline-width:0}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:inherit}b,strong{font-weight:bolder}dfn{font-style:italic}h1{font-size:2em;margin:0.67em 0}mark{background-color:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-0.25em}sup{top:-0.5em}img{border-style:none}svg:not(:root){overflow:hidden}code,kbd,pre,samp{font-family:monospace, monospace;font-size:1em}figure{margin:1em 40px}hr{box-sizing:content-box;height:0;overflow:visible}button,input,optgroup,select,textarea{font:inherit;margin:0}optgroup{font-weight:bold}button,input{overflow:visible}button,select{text-transform:none}button,html [type="button"],[type="reset"],[type="submit"]{-webkit-appearance:button}button::-moz-focus-inner,[type="button"]::-moz-focus-inner,[type="reset"]::-moz-focus-inner,[type="submit"]::-moz-focus-inner{border-style:none;padding:0}button:-moz-focusring,[type="button"]:-moz-focusring,[type="reset"]:-moz-focusring,[type="submit"]:-moz-focusring{outline:1px dotted ButtonText}fieldset{border:1px solid #c0c0c0;margin:0 2px;padding:0.35em 0.625em 0.75em}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}textarea{overflow:auto}[type="checkbox"],[type="radio"]{box-sizing:border-box;padding:0}[type="number"]::-webkit-inner-spin-button,[type="number"]::-webkit-outer-spin-button{height:auto}[type="search"]{-webkit-appearance:textfield;outline-offset:-2px}[type="search"]::-webkit-search-cancel-button,[type="search"]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-input-placeholder{color:inherit;opacity:0.54}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}</style>
        <style>
        html, body, td, input {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Oxygen", "Ubuntu", "Cantarell", "Fira Sans", "Droid Sans", "Helvetica Neue", sans-serif;
        }

        * {
            box-sizing: border-box;
        }

        html {
            font-size: 15px;
            line-height: 1.6;
            background: #fff;
            color: #{@style.text_color};
        }

        @media (max-width: 768px) {
            html {
                 font-size: 14px;
            }
        }

        @media (max-width: 480px) {
            html {
                 font-size: 13px;
            }
        }

        button:focus,
        summary:focus {
            outline: 0;
        }

        summary {
            cursor: pointer;
        }

        pre {
            font-family: #{@style.monospace_font};
            max-width: 100%;
        }

        .heading-block {
            background: #f9f9fa;
        }

        .heading-block,
        .output-block {
            padding: 48px;
        }

        @media (max-width: 768px) {
            .heading-block,
            .output-block {
                padding: 32px;
            }
        }

        @media (max-width: 480px) {
            .heading-block,
            .output-block {
                padding: 16px;
            }
        }

        /*
         * Exception logo
         */

        .exception-logo {
            position: absolute;
            right: 48px;
            top: 48px;
            pointer-events: none;
            width: 100%;
        }

        .exception-logo:before {
            content: '';
            display: block;
            height: 64px;
            width: 100%;
            background-size: auto 100%;
            background-image: url("#{@style.logo}");
            background-position: right 0;
            background-repeat: no-repeat;
            margin-bottom: 16px;
        }

        @media (max-width: 768px) {
            .exception-logo {
                position: static;
            }

            .exception-logo:before {
                height: 32px;
                background-position: left 0;
            }
        }

        @media (max-width: 480px) {
            .exception-logo {
                display: none;
            }
        }

        /*
         * Exception info
         */

        /* Compensate for logo placement */
        @media (min-width: 769px) {
            .exception-info {
                max-width: 90%;
            }
        }

        .exception-info > .error,
        .exception-info > .subtext,
        .exception-info > .title {
            margin: 0;
            padding: 0;
        }

        .exception-info > .error {
            font-size: 1em;
            font-weight: 700;
            color: #{@style.primary};
        }

        .exception-info > .subtext {
            font-size: 1em;
            font-weight: 400;
            color: #{@style.accent};
        }

        .exception-info > .title {
            font-size: #{:math.pow(1.2, 4)}em;
            line-height: 1.4;
            font-weight: 300;
            color: #{@style.primary};
        }

        @media (max-width: 768px) {
            .exception-info > .title {
                font-size: #{:math.pow(1.15, 4)}em;
            }
        }

        @media (max-width: 480px) {
            .exception-info > .title {
                font-size: #{:math.pow(1.1, 4)}em;
            }
        }

        .code-block {
            margin: 0;
            font-size: .85em;
            line-height: 1.6;
        }
        </style>
    </head>
    <body>
        <div class="heading-block">
            <aside class="exception-logo"></aside>
            <header class="exception-info">
                <h5 class="error">#{error}</h5>
                <h1 class="title">#{headline}</h1>
                <h5 class="subtext">Console output is shown below.</h5>
            </header>
        </div>
        <div class="output-block">
            <pre class="code code-block">#{format_output(output)}</pre>
        </div>
    </body>
    </html>
    """
  end

  defp format_output(output) do
    output
    |> String.trim
    |> Plug.HTML.html_escape
  end

  defp get_error_details(output) do
    case Regex.run(~r/(?:\n|^)\*\* \(([^ ]+)\) (.*)(?:\n|$)/, output) do
      [_, error, headline] -> {error, format_output(headline)}
      _ -> {"CompileError", "Compilation error"}
    end
  end
end
