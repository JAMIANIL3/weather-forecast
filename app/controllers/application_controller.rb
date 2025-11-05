class ApplicationController < ActionController::Base
  # Top-level application controller. The project uses a modern browser policy
  # to prefer features such as WebP, web push, import maps, and modern CSS.
  #
  # `allow_browser versions: :modern` is a convenience for ensuring the app's
  # progressive features are only advertised to supported browsers.
  allow_browser versions: :modern

  # When the importmap changes, it can change the JS served to the client. This
  # helper updates HTML etags when importmap changes occur so caches are
  # invalidated appropriately.
  stale_when_importmap_changes
end
