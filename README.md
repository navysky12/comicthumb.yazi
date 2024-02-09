# comicthumb.yazi

Plugin for [Yazi](https://github.com/sxyazi/yazi) to preview comic book archive files using p7zip. To install, clone the repo inside your `~/.config/yazi/plugins/`:

```bash
git clone https://github.com/navysky12/comicthumb.yazi.git
```

and add comicthumb.sh to `PATH` before including it in your `yazi.toml`:

```toml
[plugin]
prepend_previewers = [
  { name = "*.cbz", exec = "comicthumb" },
]
```

Make sure you have p7zip installed, and can be found in `PATH`.

