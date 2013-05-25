#==============================================================================
# Å° BattleManager
#==============================================================================

module BattleManager
  
  #--------------------------------------------------------------------------
  # self.setup_tbs
  #--------------------------------------------------------------------------
  def self.setup_tbs(can_escape, can_lose)
    @can_escape = can_escape
    @can_lose   = can_lose
    init_tbs
  end
  
  #--------------------------------------------------------------------------
  # self.init_tbs
  #--------------------------------------------------------------------------
  def self.init_tbs
    $game_troop.setup_tbs($game_map.enemy_troop)
    make_escape_ratio
    #---
    @phase = :init
    @map_bgm = nil
    @map_bgs = nil 
    @action_battlers = []   
  end
  
  #--------------------------------------------------------------------------
  # self.tbs_start
  #--------------------------------------------------------------------------
  def self.tbs_start
    $game_system.battle_count += 1
    $game_party.on_tbs_start
    $game_troop.on_tbs_start
    $game_troop.enemy_names.each do |name|
      $game_message.add(sprintf(Vocab::Emerge, name))
    end
    wait_for_message
  end
    
end # BattleManager