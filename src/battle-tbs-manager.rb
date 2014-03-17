#==============================================================================
# ■ BattleManager
#==============================================================================

module BattleManager
  
  #--------------------------------------------------------------------------
  # self.setup_tbs
  #--------------------------------------------------------------------------
  def self.setup_tbs(can_escape, can_lose, max_actor)
    @can_escape = can_escape
    @can_lose   = can_lose
    @max_actor  = max_actor
    init_tbs
  end
  
  #--------------------------------------------------------------------------
  # self.max_actor
  #--------------------------------------------------------------------------
  def self.max_actor
    @max_actor
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
  
  #--------------------------------------------------------------------------
  # self.tbs_turn_start
  #--------------------------------------------------------------------------
  def self.tbs_turn_start
    @phase = :turn
  end
  
  #--------------------------------------------------------------------------
  # self.setup_tbs_order
  #--------------------------------------------------------------------------
  def self.setup_tbs_order
    @action_battlers.clear
    #---
    @action_battlers += $game_party.members
    @action_battlers += $game_troop.members
    @action_battlers.sort! { |a, b| b.agi <=> b.agi }
  end
  
  #--------------------------------------------------------------------------
  # self.setup_tbs_order_test
  #--------------------------------------------------------------------------
  def self.setup_tbs_order_test
    @action_battlers.clear
    #---
    @action_battlers += $game_party.members
    @action_battlers.sort! { |a, b| b.agi <=> a.agi }
  end
  
  #--------------------------------------------------------------------------
  # self.get_active_battler
  #--------------------------------------------------------------------------
  def self.get_active_battler
    setup_tbs_order_test if @action_battlers.nil? || @action_battlers.size == 0
    loop do
      battler = @action_battlers.shift
      setup_tbs_order_test if battler.nil?
      next unless battler
      next unless battler.index && battler.alive?
      return battler
    end
  end
  
  #--------------------------------------------------------------------------
  # self.phase
  #--------------------------------------------------------------------------
  def self.phase
    @phase
  end
    
end # BattleManager