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
    logo: "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhLS0gQ3JlYXRlZCB3aXRoIElua3NjYXBlIChodHRwOi8vd3d3Lmlua3NjYXBlLm9yZy8pIC0tPgo8c3ZnIGlkPSJzdmcyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbDpzcGFjZT0icHJlc2VydmUiIGhlaWdodD0iNDAyLjE4IiB3aWR0aD0iMzE4LjIyIiB2ZXJzaW9uPSIxLjAiPjxwYXRoIGlkPSJleGNsdXNpb24tem9uZSIgZD0ibTY4LjU5NCAxMzEuMDVoMjUzLjc5djMyMC43NGgtMjUzLjc5bDAuMDA0LTMyMC43NHoiIHRyYW5zZm9ybT0ibWF0cml4KDEuMjUzOSAwIDAgLTEuMjUzOSAtODYuMDEgNTY2LjUpIiBmaWxsPSIjZmZmIi8+PHBhdGggaWQ9IkZULVBpbmsiIGQ9Im0yMzUuNDkgNTU3LjA3djE3OC45NGgxNzguOTN2LTE3OC45NGgtMTc4LjkzeiIgdHJhbnNmb3JtPSJtYXRyaXgoMCAtMS4yNSAtMS4yNSAwIDk2Ni42MiA1NjUuOTkpIiBmaWxsPSIjZmNkMGFmIi8+PHBhdGggaWQ9IkZUIiBkPSJtLTM5LjIyNyA0NzkuODFjMC04LjQ1IDIuMjU0LTkuMzkgMTEuODgyLTkuNzV2LTMuMDloLTM4LjI2OXYzLjA5YzcuOTYxIDAuMzYgMTAuMjE5IDEuMyAxMC4yMTkgOS43NXY1NS4xNGMwIDguNDUtMi4yNTggOS40LTkuOTgxIDkuNzV2My4wOWg2Ny41MDRsMC40ODA1LTE3LjgyaC0zLjMyOWMtMi44NTEgOS4wMy01Ljk0NSAxMS44OC0yMS43NTIgMTEuODhoLTEyLjI0OGMtMy42NzUgMC00LjUwNy0wLjgzLTQuNTA3LTQuMTZ2LTI1LjU2aDYuMDMxYzEyLjYwMSAwIDE1LjMzNiAyLjI3IDE2Ljg3OSAxMC43MWgzLjA5di0yOC41M2gtMy4wOWMtMS42NiA5LjUxLTYuNDE4IDExLjg4LTE2Ljg3OSAxMS44OGgtNi4wMzF2LTI2LjM4em0xMTcuOCA2Ny45OGgtNzAuODRsLTEuNjQ0NS0xNy44M2g0LjA2MzVjMi41OTMgOC43MyA2LjQwNiAxMS44OSAxNC45MzMgMTEuODloOS45ODV2LTYyLjA0YzAtOC40NS0yLjI1OC05LjM5LTExLjQwNy05Ljc1di0zLjA5aDM4Ljk4NXYzLjA5Yy05LjE1MyAwLjM2LTExLjQxIDEuMy0xMS40MSA5Ljc1djYyLjA0aDkuOThjOC41MzEgMCAxMi4zNDgtMy4xNiAxNC45MzctMTEuODloNC4wNTlsLTEuNjQxIDE3LjgzeiIgdHJhbnNmb3JtPSJtYXRyaXgoMS4yNSAwIDAgLTEuMjUgMTUyLjg1IDc2NC40NSkiIGZpbGw9IiMzZTQ3NGYiLz48cGF0aCBpZD0iRmluYW5jaWFsVGltZXMiIGQ9Im0tNzguNTU1IDM2NC4yNGMwLTIuMTYgMC41ODItMi40IDMuMDQzLTIuNXYtMC43N2gtOS43OTd2MC43N2MyLjAzNSAwLjEgMi42MTcgMC4zNCAyLjYxNyAyLjV2MTQuMTJjMCAyLjE3LTAuNTgyIDIuNDEtMi41NjMgMi41djAuNzloMTcuMjk3bDAuMTE3LTQuNTZoLTAuODUxYy0wLjczMSAyLjMxLTEuNTIgMy4wNC01LjU3IDMuMDRoLTMuMTM3Yy0wLjk0MiAwLTEuMTU2LTAuMjEtMS4xNTYtMS4wN3YtNi41NGgzLjUzNWMzLjIyNiAwIDMuOTI1IDAuNTggNC4zMiAyLjc0aDAuNzkzdi03LjMxaC0wLjc5M2MtMC40MjYgMi40NC0xLjY0NSAzLjA1LTQuMzIgMy4wNWgtMy41MzV2LTYuNzZ6bTIwLjM5OCAwYzAtMi4xNiAwLjU3NC0yLjQgMy4wNDMtMi41di0wLjc3aC0xMC4yMzF2MC43N2MyLjQ3MyAwLjEgMy4wNDMgMC4zNCAzLjA0MyAyLjV2MTQuMTJjMCAyLjE3LTAuNTcgMi40MS0zLjA0MyAyLjV2MC43OWgxMC4yMzF2LTAuNzljLTIuNDY5LTAuMDktMy4wNDMtMC4zMy0zLjA0My0yLjV2LTE0LjEyem0yNC4zODMgMTMuNTRjMCAyLjAxLTAuNTUxIDIuODMtMi44MDUgMy4wOHYwLjc5aDcuMzA1di0wLjc5Yy0yLjI1LTAuMjUtMi43OTctMS4wNy0yLjc5Ny0zLjA4di0xNy4zMmgtMS4wMzVsLTE0LjEyMSAxNi4zMnYtMTEuOTZjMC0yLjAxIDAuNTQzLTIuODMgMi43OTctMy4wOHYtMC43N2gtNy4zMDl2MC43N2MyLjI1NCAwLjI1IDIuODAxIDEuMDcgMi44MDEgMy4wOHYxMy45M2MtMC42OTkgMS4yMy0xLjUyNCAxLjgxLTIuODAxIDIuMTF2MC43OWg1LjYzM2wxMi4zMzItMTQuMjV2MTAuMzh6bTExLjA0Ny05LjRsMy4xMDUgOC4xOSAzLjA3OC04LjE5aC02LjE4M3ptMTQuODI0LTcuNDF2MC43N2MtMS41NTEtMC4wMy0xLjk0NSAwLjY0LTIuNzM3NSAyLjU5bC03LjI3OCAxNy44MWgtMWwtNy41ODItMTguNDVjLTAuNTE5LTEuMjgtMS4yMTktMS42Ny0yLjUyNy0xLjk1di0wLjc3aDYuNTc0djAuNzdjLTEuNDMgMC0yLjEyOSAwLjMxLTIuMTI5IDEuMzEgMCAwLjg1IDAuOTQ2IDMuMTQgMS4xODQgMy44MWg3LjQ5MmMwLjI0Mi0wLjY3IDEuMjQ2LTIuOTYgMS4yNDYtMy44MSAwLTEtMC43NTgtMS4zMS0yLjE5MS0xLjMxdi0wLjc3aDguOTQ4NXptMjAuMDYyIDE2LjgxYzAgMi4wMS0wLjU0NiAyLjgzLTIuNzk2NSAzLjA4djAuNzloNy4zMDQ1di0wLjc5Yy0yLjI1NC0wLjI1LTIuODA0LTEuMDctMi44MDQtMy4wOHYtMTcuMzJoLTEuMDMybC0xNC4xMjYgMTYuMzIgMC4wMDA1LTExLjk2YzAtMi4wMSAwLjU0NzAzLTIuODMgMi44MDEtMy4wOHYtMC43N2gtNy4zMDl2MC43N2MyLjI1NCAwLjI1IDIuODA1IDEuMDcgMi44MDUgMy4wOHYxMy45M2MtMC43MDMgMS4yMy0xLjUyNyAxLjgxLTIuODA1IDIuMTF2MC43OWg1LjYzM2wxMi4zMjgtMTQuMjUgMC4wMDEgMTAuMzh6bTI2LjEzNy0xMS45NWMtMi4xNjQtMy42OS00Ljk5Ni01LjM3LTkuMjg5LTUuMzctNi43MjcgMC0xMC43MTUgNC40Mi0xMC43MTUgMTEuMDMgMCA0LjcxIDMuNzE1IDEwLjY1IDEwLjkzIDEwLjY1IDIuMTYgMCA1LjIzLTEuMjIgNS42OTEtMS4yMiAwLjYwNiAwIDAuNzg5IDAuMzMgMS4yODIgMS4yMmgxLjAzMWwwLjQyOS02LjkxaC0wLjkxNGMtMS4yMjIgMy4yLTMuMzc4IDUuNTEtNy4wMDMgNS41MS00Ljg3MiAwLTctNS4yNy03LTkuMjUgMC01LjU4IDIuNDAyLTkuMzIgNy41NS05LjMyIDQuMDE2IDAgNi4yMzkgMi45OCA3LjE4NCA0LjI5bDAuODI0LTAuNjN6bTEwLjAyNC0xLjU5YzAtMi4xNiAwLjU4Mi0yLjQgMy4wNDYtMi41di0wLjc3aC0xMC4yM3YwLjc3YzIuNDY5IDAuMSAzLjA0NyAwLjM0IDMuMDQ3IDIuNXYxNC4xMmMwIDIuMTctMC41NzggMi40MS0zLjA0NyAyLjV2MC43OWgxMC4yM3YtMC43OWMtMi40NjQtMC4wOS0zLjA0Ni0wLjMzLTMuMDQ2LTIuNXYtMTQuMTJ6bTExLjUyMyA0LjE0bDMuMTA1IDguMTkgMy4wNzUtOC4xOWgtNi4xOHptMTQuODI4LTcuNDF2MC43N2MtMS41NTUtMC4wMy0xLjk0OSAwLjY0LTIuNzM4IDIuNTlsLTcuMjc4IDE3LjgxaC0xLjAwM2wtNy41ODItMTguNDVjLTAuNTItMS4yOC0xLjIxOS0xLjY3LTIuNTI4LTEuOTV2LTAuNzdoNi41NzR2MC43N2MtMS40MjkgMC0yLjEyOCAwLjMxLTIuMTI4IDEuMzEgMCAwLjg1IDAuOTQ1IDMuMTQgMS4xODcgMy44MWg3LjQ4OGMwLjI0Mi0wLjY3IDEuMjQ2LTIuOTYgMS4yNDYtMy44MSAwLTEtMC43NjEtMS4zMS0yLjE5MS0xLjMxdi0wLjc3aDguOTUzem0xLjgwOSAwdjAuNzdjMS45OCAwLjA5IDIuNTU4IDAuMzQgMi41NTggMi41djE0LjEyYzAgMi4xNy0wLjU3OCAyLjQxLTIuNTU4IDIuNXYwLjc5aDkuNTU4di0wLjc5Yy0yLjI4MS0wLjA5LTIuODYzLTAuMzMtMi44NjMtMi41di0xNC41MmMwLTEuMjUgMC4zNjctMS42NyAyLjY4LTEuNjcgMy43MTUgMCA1LjkwNiAwLjY3IDcuNjcyIDQuMzJoMC43OTNsLTEuMzk5LTUuNTJoLTE2LjQ0MXptLTE1Ny4yNS0zMi42MmMyLjM1MSAwLjEgMi45MjUgMC4zNCAyLjkyNSAyLjV2MTUuODloLTIuNTU0Yy0yLjQwNiAwLTMuMzUyLTAuOTctNC4wMi0zLjc3aC0wLjkxNGwwLjQ4OCA1LjI5aDE4LjE0MWwwLjQ4OC01LjI5aC0wLjkxOGMtMC42NjQgMi44LTEuNjA5IDMuNzctNC4wMTEgMy43N2gtMi41NTl2LTE1Ljg5YzAtMi4xNiAwLjU3OC0yLjQgMi45MTgtMi41di0wLjc3aC05Ljk4NHYwLjc3em0yMy44NjcgMi41YzAtMi4xNiAwLjU4Mi0yLjQgMy4wNDctMi40OXYtMC43OGgtMTAuMjMxdjAuNzhjMi40NzMgMC4wOSAzLjA0NyAwLjMzIDMuMDQ3IDIuNDl2MTQuMTNjMCAyLjE2LTAuNTc0IDIuNC0zLjA0NyAyLjQ5djAuOGgxMC4yMzF2LTAuOGMtMi40NjUtMC4wOS0zLjA0Ny0wLjMzLTMuMDQ3LTIuNDl2LTE0LjEzem0yNC43NzcgMTcuNDFoNy4xMjV2LTAuNzljLTEuOTgtMC4wOS0yLjU1NC0wLjMzLTIuNTU0LTIuNDl2LTE0LjEzYzAtMi4xNiAwLjU3NC0yLjQgMi41NTQtMi41di0wLjc3aC05LjMxNnYwLjc3YzIuMDM5IDAuMSAyLjYyMSAwLjM0IDIuNjIxIDIuNXYxNC41NWgtMC4wNjNsLTYuOTEtMTguMDhoLTAuOTQ1bC02Ljc1NCAxOC4wOGgtMC4wNjJ2LTEzLjk3YzAtMi4wMSAwLjU0Ni0yLjgzIDIuOC0zLjA4di0wLjc3aC03LjMwNHYwLjc3YzIuMjUgMC4yNSAyLjc5NyAxLjA3IDIuNzk3IDMuMDh2MTQuMDZjMCAxLjQzLTAuNjA2IDEuOTgtMi43OTcgMS45OHYwLjc5aDcuNTE5bDUuNTA4LTE0LjM2IDUuNzgxIDE0LjM2em0xMC4wNjMtMjAuNjh2MC43N2MxLjk3NiAwLjEgMi41NTQgMC4zNCAyLjU1NCAyLjV2MTQuMTNjMCAyLjE2LTAuNTc4IDIuNC0yLjU1NCAyLjQ5djAuNzloMTcuMjg4bDAuMTIxNS00LjU2aC0wLjg0OGMtMC43MzQgMi4zMS0xLjUyNyAzLjA0LTUuNTczNSAzLjA0aC0zLjEzM2MtMC45NDkgMC0xLjE1Ni0wLjIxLTEuMTU2LTEuMDZ2LTYuNTVoMy41MjdjMy4yMjY1IDAgMy45MjU1IDAuNTggNC4zMjQ1IDIuNzRoMC43OTJ2LTcuM2gtMC43OTJjLTAuNDMgMi40My0xLjY0NSAzLjA0LTQuMzI0NSAzLjA0aC0zLjUyN3YtNy4xNmMwLTEuMjQgMC4zNjMtMS42NyA0LjAxNi0xLjY3IDMuNzEwNSAwIDUuOTA1NSAwLjY3IDcuNjcwNSA0LjMzaDAuNzlsLTEuMzk5LTUuNTNoLTE3Ljc3NnptMjEuODY3IDYuNWgwLjc5N2MwLjg3ODk3LTIuNzQgMy41LTUuNiA2LjU0Ny01LjYgMi42MTMgMCAzLjU1ODUgMS44MiAzLjU1ODUgMy40NCAwIDQuNzUtMTAuNzE1IDUuNjMtMTAuNzE1IDExLjUzLTAuMDAwNDcgMi44NiAyLjc2OTUgNS4zIDUuOTMzNSA1LjMgMy4xMDUgMCA0LjE5OTUtMS4wOSA1LjU3NDUtMS4wOSAwLjU3OCAwIDAuOTQyIDAuNDUgMS4wOTQgMS4wOWgwLjc5M3YtNi41N2gtMC43OTNjLTAuODUyIDIuOTgtMi45ODA1IDUuMTctNS43ODU1IDUuMTctMi4zMDkgMC0zLjE2OC0xLjQ5LTMuMTY4LTIuOSAwLTQuMjIgMTAuNzItNC4zNSAxMC43Mi0xMS42Mi0wLjAwMS0zLjI1LTIuNjc3LTUuNzUtNi4zOTY1LTUuNzUtMy42NTIgMC00LjU5NCAxLjI3LTYuMDI3IDEuMjctMC41NDMgMC0wLjkxNC0wLjM2LTEuMDMyLTEuMDNoLTEuMTAxbDAuMDAwMDMgNi43NnoiIHRyYW5zZm9ybT0ibWF0cml4KDEuMjUgMCAwIC0xLjI1IDE1Mi44NSA3NjQuNDUpIiBmaWxsPSIjM2U0NzRmIi8+PC9zdmc+Cg==",
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
