# Overlay to allow unfree packages globally
{ ... }:
final: prev: {
  config = prev.config // { allowUnfree = true; };
}
