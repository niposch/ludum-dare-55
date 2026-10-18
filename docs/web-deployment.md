# Browser publication

This is Nick's fork of [panorb/ludum-dare-55](https://github.com/panorb/ludum-dare-55). Team authorship and original credits are preserved.

Play at **https://niposch.de/ludum-dare-55/**. GitHub Pages inherits the custom domain from `niposch/niposch.github.io`; there is no project CNAME or separate DNS/ingress route.

Pages uses GitHub Actions (`build_type: workflow`). Push source changes to `master` or manually dispatch `.github/workflows/web-export.yml`. The workflow downloads the official Godot **4.3** editor and matching templates, checks their SHA-512 release sums, fully imports resources (including generated translations), exports the `Web` preset and deploys `build/web`. Generated binaries are not committed. The engine version is pinned to retain these jam-era games' compatibility; update only with a gameplay check.

The web preset explicitly disables threads and PWA caching. This avoids the SharedArrayBuffer/cross-origin-isolation header requirement on static GitHub Pages. All generated resources use relative URLs, so the game runs under its repository subdirectory. LD54's previous `gh-pages` export required isolation and failed before startup; the Actions deployment replaces that published artifact without deleting historical branches.

Local equivalent with the official Godot 4.3 editor and web templates installed:

```sh
godot --headless --path godot --editor --import
mkdir -p build/web
godot --headless --path godot --export-release Web "$PWD/build/web/index.html"
python -m http.server --directory build/web 8080
```

Open http://localhost:8080/ rather than the HTML file directly. Before publishing changes, verify menu/gameplay and console errors in a browser. A successful export alone is not a play test.
