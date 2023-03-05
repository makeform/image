module.exports =
  pkg:
    name: "@makeform/image", extend: {name: '@makeform/upload'}
    dependencies: [
      {url: "https://cdn.jsdelivr.net/npm/imgtype@0.0.1/index.min.js"}
    ]

  init: ({ctx, root, parent}) ->
    {imgtype} = ctx
    is-supported = (file) ->
      (res, rej) <- new Promise _
      try
        fr = new FileReader!
        fr.onload = ->
          ({ext, mime}) <- imgtype(new Uint8Array fr.result).then _
          res if !ext => {supported: false} else {supported: true}
        fr.readAsArrayBuffer(file)
      catch e
        rej e
    view = new ldview do
      root: root
      ctx: {}
      handler:
        image:
          list: ({ctx}) ->
            file = ctx.file
            if Array.isArray(file) => file else if file => [file] else []
          view:
            handler:
              image: ({node,ctx}) -> node.setAttribute \src, ctx.url

    parent.ext {view, is-supported}
