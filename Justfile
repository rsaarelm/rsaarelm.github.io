#set shell := ["sh"]

repository := "git@github.com:rsaarelm/rsaarelm.github.io"

# Run a local webserver to test the site.
serve source='./site/': (build source)
    @echo Running test server at http://localhost:8080/
    # Run entr to regenerate the site whenever a post changes.
    # Set Ctrl-C to stop both the background server and the updater daemon.
    #
    # XXX: You must restart `just serve` if you add new posts after starting
    # it, entr will only run on the posts that are present when the server was
    # started.
    @(trap 'kill 0' SIGINT; caddy run & (find {{source}} ./static/ ./templates/ | entr just build {{source}}) )

build source='./site/':
    cargo run -- --source {{source}}

# One-time operation to activate versioned githooks.
register-githooks:
    git config --local core.hooksPath githooks/

# Use local build to publish to gh-pages.
publish:
    #!/bin/sh
    rm -rf public/
    cargo run
    DIR=$(mktemp -d)
    cp -r public/* $DIR/
    cd $DIR/
    git init --initial-branch=master
    git add .
    git commit -m "Automated deployment to gh-pages"
    git push --force {{repository}} master:gh-pages
    cd -
    rm -rf $DIR/

# Check link health for the website deployed to GH pages.
check-links:
    linkchecker --check-extern https://rsaarelm.github.io/links/

# Test any Rust code examples embedded in blog posts.
#
# See src/lib.rs for registry of posts to embed for testing.
test-examples:
    cargo test
