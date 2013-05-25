module HARMONY
  module VISUAL
    PANEL_COLORS = { # Start.
      :start          => [32 , 32 , 255, 128],
      :move           => [16 , 16 , 255, 128],
      :enemy_target   => [255, 32 , 32 , 128],
      :ally_target    => [32 , 255, 32 , 128],
      :cursor         => [255, 255, 32 , 192],
      :other          => [255, 255, 255, 128],
    } # End.
    PANEL_OUTLINE = true
  end # VISUAL
  
  module ENGINE
    DEFAULT_PROPERTIES = { # Start.
      # Initialize Range for Movement, Attack, Skill and Item.
      :move_range     =>  4,
      :attack_range   =>  1,
      :skill_range    =>  1,
      :item_range     =>  1,
    } # End.
    
    PARTY_START_REGION = 30
    DEFAULT_BATTLE_MEMBERS = 4
  end # ENGINE
end # HARMONY

module Vocab
  
  def self.tbs_place
    # Place Command
    "Place"
  end
  
  def self.tbs_fight
    # Start Battle Command
    "Fight"
  end
  
  def self.tbs_placed
    # Use to note which actor has been placed
    "Placed"
  end
  
end # Vocab