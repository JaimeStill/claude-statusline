# Image Generation

Capture the screenshot region:

```sh
slurp ~/.statusline-region
```

Generate the screenshot:

```sh
grim -g "$(cat ~/.statusline-region)" ./images/[theme].png
```
