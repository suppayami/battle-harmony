module Harmony
  # Build filename
  FINAL   = "build/final.rb"
  # Source files
  TARGETS = [
    "src/config.rb",
    "src/data-parser.rb",
    "src/character-sprite.rb",
    "src/panel-sprite.rb",
    "src/panel-manager.rb",
    "src/astar-algorithm.rb",
    "src/battler-properties.rb",
    "src/battle-prepare.rb",
    "src/battle-map-data.rb",
    "src/battle-map-spriteset.rb",
    "src/battle-tbs-manager.rb",
    "src/window-tactical.rb",
    "src/scene-tactical-battle.rb",
    "src/call-tbs.rb",
  ]
end

def harmony_build
  final = File.new(Harmony::FINAL, "w+")
  Harmony::TARGETS.each { |file|
    src = File.open(file, "r+")
    final.write(src.read + "\n")
    src.close
  }
  final.close
end

harmony_build()
