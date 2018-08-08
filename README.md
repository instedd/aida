# A.I.D.A. (Artificially Intelligent Digital Assistant)

To start AIDA:

  * Setup the development environment with `./dev-setup.sh`
  * Start the server `docker-compose up`

Now you can visit [`ui.aida.lvh.me`](http://ui.aida.lvh.me) from your browser.

Before creating a commit, make sure to:
  * run `mix format $file` or `mix format "lib/**/*.{ex,exs}" "test/**/*.{ex,exs}"` to mantain coding [style and conventions](https://hexdocs.pm/mix/master/Mix.Tasks.Format.html).
  * run `./pre-commit.sh` to ensure every check will pass in travis.

For Websocket specific docs, go to [docs/websocket.md](docs/websocket.md)
