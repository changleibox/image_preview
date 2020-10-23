//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <imagepreview/imagepreview_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) imagepreview_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ImagepreviewPlugin");
  imagepreview_plugin_register_with_registrar(imagepreview_registrar);
}
