{ delib, lib, moduleSystem, ... }:
let
  # TEMPORARY: remove once locked nixos-unstable contains nixpkgs 3f1a26c9fa (speechrecognition) and 707c8bba2f (geopandas 1.2.0).
  openaiTests = "tests/recognizers/whisper_api/test_openai.py";
  pythonCheckFixesOverlay = _final: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (_pyFinal: pyPrev: {
        speechrecognition =
          if lib.elem openaiTests (pyPrev.speechrecognition.disabledTestPaths or [ ]) then pyPrev.speechrecognition
          else
            pyPrev.speechrecognition.overridePythonAttrs (old: {
              disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [ openaiTests ];
            });

        geopandas =
          if pyPrev.geopandas.version != "1.1.4" then pyPrev.geopandas
          else
            pyPrev.geopandas.overridePythonAttrs (old: {
              disabledTests = (old.disabledTests or [ ]) ++ [
                "test_geoarrow_roundtrip"
                "test_geoarrow_missing"
                "test_read_file_crs_warning_messages"
                "test_read_file_mask_gdf"
                "test_read_file_mask_polygon"
                "test_read_file_mask_geojson"
                "test_read_file_mask_gdf_mismatched_crs"
                "test_read_file_multi_layer_with_layer_arg_no_warning"
              ];
            });
      })
    ];
  };
in
delib.module {
  name = "python-check-fixes-overlay";

  nixos.always.nixpkgs.overlays = [ pythonCheckFixesOverlay ];
  darwin.always.nixpkgs.overlays = [ pythonCheckFixesOverlay ];
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = [ pythonCheckFixesOverlay ];
  };
}
