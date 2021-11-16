let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.14.3/src/packages.dhall sha256:1f9af624ddfd5352455b7ac6df714f950d499e7e3c6504f62ff467eebd11042c

in  upstream
      with elmish.version = "v0.5.6"
