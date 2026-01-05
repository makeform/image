module.exports =
  pkg:
    name: \@makeform/image
    extend: name: \@makeform/upload
    host: name: \@grantdash/composer
    dependencies: [
    * url: "https://cdn.jsdelivr.net/npm/imgtype@0.0.1/index.min.js"
    ]
    i18n:
      "zh-TW":
        "image required": "檔案需為可於瀏覽器中顯示的圖檔"
        config:
          crop:
            enabled: name: '啟用裁切', desc: '若啟用，將基於寬高設定裁切圖片'
            width: name: '圖寬', desc: '裁切時的預期圖寬'
            height: name: '圖高', desc: '裁切時的預期圖高'
          lightbox: enabled: name: '啟用燈箱', desc: '若啟用，點擊圖片時將彈出燈箱效果供瀏覽圖片'
      "en":
        "image required": "File must be a browser-viewable image."
        config:
          crop:
            enabled:
              name: 'enable cropping'
              desc: 'crop image based on ratio derived from width / height below if enabled'
            width: name: 'image width', desc: 'expected image width when cropped'
            height: name: 'image height', desc: 'expected image height when copped'
          lightbox: enabled: name: 'enable lightbox', desc: 'toggle a lightbox for previewing when clicking if enabled'
  client: ->
    meta: config:
      crop:
        enabled: type: \boolean, default: false, name: 'config.crop.enabled.name', desc: 'config.crop.enabled.desc'
        width: type: \number, min: 1, max: 2000, name: 'config.crop.width.name', desc: 'config.crop.width.desc'
        height: type: \number, min: 1, max: 2000, name: 'config.crop.height.name', desc: 'config.crop.height.desc'
      lightbox:
        enabled: type: \boolean, default: true, name: 'config.lightbox.enabled.name', desc: 'config.lightbox.enabled.desc'

  init: ({ctx, root, parent, t}) ->
    {imgtype} = ctx
    lc = {meta: {}, crop: {}}
    _sizehash = {}
    get-size = ({url, node}) ->
      if _sizehash{}[url].data => return Promise.resolve that
      if !node or _sizehash[url].running => return new Promise (res, rej) -> _sizehash[url].[]queue.push {res, rej}
      _sizehash[url].running = true
      (res, rej) <- new Promise _
      img = new Image!
      finish = (opt) ->
        res(_sizehash[url].data = opt)
        _sizehash[url].[]queue.for-each ({res}) -> res opt
      img.onerror = -> finish {ratio: 1.5, width: 150, height: 100}
      img.onload = ->
        {width, height} = img{width, height}
        ratio = width / height
        box = node.getBoundingClientRect!
        limit =
          width: min: 200, max: box.width
          height: min: 100, max: (600 <? window.innerHeight * 0.8)
        rmax = Math.min(limit.height.max / height, limit.width.max / width)
        rmin = Math.max(limit.height.min / height, limit.width.min / width) >? 1
        r = (rmin <? rmax)
        width = width * r
        height = height * r
        finish {ratio, width, height}
      img.src = url

    is-supported = (file) ->
      (res, rej) <- new Promise _
      try
        fr = new FileReader!
        fr.onload = ->
          ({ext, mime}) <- imgtype(new Uint8Array fr.result).then _
          res if !ext => {supported: false, message: t("image required")} else {supported: true}
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
              if lc.lightbox.enabled? and !lc.lightbox.enabled => return
              lc.viewer.innerHTML = ""
              img = new Image!
              img.src = ctx.url
              lc.viewer.appendChild img
              lc.open.setAttribute \href, ctx.url
              lc.ldcv.toggle!

            handler:
              "@": ({node, ctx}) ~>
                ({width, height, ratio}) <- get-size {url: ctx.url, node} .then _
                node.classList.toggle \crop, !!lc.crop.enabled
              "image-base": ({node, ctx}) ->
                ({width, height, ratio}) <- get-size {url: ctx.url} .then _
                node.style <<< if !lc.crop.enabled => aspect-ratio: '', background-image: ''
                else aspect-ratio: ratio, background-image: "url(#{ctx.url})"

              image: ({node,ctx}) ~>
                node.setAttribute \src, ctx.url
                node.style.opacity = 0
                if !lc.crop.enabled =>
                  node.style <<< opacity: 1, ratio: '', width: '', height: ''
                  return
                ({width, height, ratio}) <- get-size {url: ctx.url, node} .then _
                real = width: lc.crop.width, height: lc.crop.height
                crop-ratio = (real.width / real.height)
                node.setAttribute \width, real.width
                node.setAttribute \height, real.height
                node.style <<< aspect-ratio: crop-ratio, opacity: 1
                node.style <<< (
                  if crop-ratio > ratio => height: "auto", width: "100%"
                  else height: "100%", width: "auto"
                )

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

    render = ->
      if lc.widget => return
      lc.widget = @
      _ = ->
        lc.meta = lc.widget.serialize!
        lc.crop = ((lc.meta.config or {}).crop or {})
        lc.lightbox = ((lc.meta.config or {}).lightbox or {})
        view.render!
      _!
      @on \meta, -> _!
    parent.ext {view, is-supported, detail, render}
