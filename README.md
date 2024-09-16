# comicthumb.yazi

Plugin for [Yazi](https://github.com/sxyazi/yazi) to preview comic book archive files using p7zip.
To install:

```bash
ya pack -a navysky12/comicthumb.yazi
```

and reference it in your `yazi.toml`:

```toml
[plugin]
prepend_preloaders = [
	{ name = "*.cbz", run = "comicthumb" },
]
prepend_previewers = [
	{ name = "*.cbz", run = "comicthumb" },
]
```
