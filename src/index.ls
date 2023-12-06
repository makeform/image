module.exports =
  pkg:
    name: "@makeform/image", extend: {name: '@makeform/upload'}
    dependencies: [
      {url: "https://cdn.jsdelivr.net/npm/imgtype@0.0.1/index.min.js"}
    ]

  init: ({ctx, root, parent}) ->
    {imgtype} = ctx
    lc = {}
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
      init:
        dialog: ({node}) ->
          lc.ldcv = new ldcover root: node
          lc.viewer  = ld$.find(node, '[ld=container]',0)
          lc.open  = ld$.find(node, '[ld=open]',0)
      handler:
        image:
          list: ({ctx}) ->
            file = ctx.file
            if Array.isArray(file) => file else if file => [file] else []
          view:
            action: click: "@": ({ctx}) ->
              lc.viewer.innerHTML = ""
              img = new Image!
              img.src = ctx.url
              lc.viewer.appendChild img
              lc.open.setAttribute \href, ctx.url
              lc.ldcv.toggle!

            handler:
              image: ({node,ctx}) -> node.setAttribute \src, ctx.url

    detail = (v) ->
      ps = v.map (f) ->
        (res, rej) <- new Promise _
        img = new Image!
        img.onload = ->
          {width, height} = img{width, height}
          ret = {width, height} <<< (
            if width > height => {long: width, short: height}
            else {long: height, short: width}
          )
          ret.pixels = ret.width * ret.height
          URL.revokeObjectURL img.src
          res(f <<< ret)
        img.src = URL.createObjectURL(f.blob)
      Promise.all ps

    parent.ext {view, is-supported, detail}
