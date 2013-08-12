# Panel Manager, use to find targetable grids.

#==============================================================================
# ¡ö PanelManager
#==============================================================================

module PanelManager
  
  #--------------------------------------------------------------------------
  # clear
  #--------------------------------------------------------------------------
  def self.clear
    @selection ||= []; @selection.clear
    @open ||= []; @open.clear
    @close ||= []; @close.clear
    @cost ||= []; @cost.clear
    (0...$game_map.width).each { |x|
      (0...$game_map.height).each { |y|
        @cost[x] ||= []
        @cost[x][y] = 0
      }
    }
  end
  
  #--------------------------------------------------------------------------
  # selection
  #--------------------------------------------------------------------------
  def self.selection
    @selection
  end
  
  #--------------------------------------------------------------------------
  # block_moves
  #--------------------------------------------------------------------------
  def self.block_moves
    result = []
    objects = $game_map.actor_party + $game_map.enemy_troop
    objects.each { |object| result.push([object.x, object.y]) }
    result
  end
  
  #--------------------------------------------------------------------------
  # check_last
  #--------------------------------------------------------------------------
  def self.check_last(battler, action, base)
    @last_battler == battler && @last_action == action && 
      @last_position == base
  end
  
  #--------------------------------------------------------------------------
  # check_passable?
  #--------------------------------------------------------------------------
  def self.check_passable?(battler, x, y, d)
    return false unless battler.character.passable?(x, y, d)
    return false unless passable?(x, y, d)
    return true
  end
  
  #--------------------------------------------------------------------------
  # passable?
  #--------------------------------------------------------------------------
  def self.passable?(x, y, d)
    panel = get_panel(x, y, d)
    #---
    return false unless $game_map.valid?(panel[0], panel[1])
    return true
  end
  
  #--------------------------------------------------------------------------
  # get_panel
  #--------------------------------------------------------------------------
  def self.get_panel(x, y, d)
    case d
    when 1; return [x - 1, y + 1]
    when 2; return [x    , y + 1]
    when 3; return [x + 1, y + 1]
    when 4; return [x - 1, y    ]
    when 6; return [x + 1, y    ]
    when 7; return [x - 1, y - 1]
    when 8; return [x    , y - 1]
    when 9; return [x + 1, y - 1]
    end
  end
  
  #--------------------------------------------------------------------------
  # move_selection
  #--------------------------------------------------------------------------
  def self.move_selection(battler, fly = false)
    action = fly ? :fly : :move
    base = [battler.x, battler.y]
    return @selection if check_last(battler, action, base)
    @last_battler = battler
    @last_action = action
    @last_position = base
    #---
    clear
    @max = battler.move_range
    setup_selection(base, !fly)
    @selection -= block_moves
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # skill_selection
  #--------------------------------------------------------------------------
  def self.skill_selection(battler, item)
    base = [battler.x, battler.y]
    return @selection if check_last(battler, item, base)
    @last_battler = battler
    @last_action = item
    @last_position = base
    #---
    case item.class.name
    when "RPG::Skill"
      range = battler.skill_range(item)
    when "RPG::Item"
      range = battler.item_range(item)
    end
    clear
    @max = battler.move_range
    setup_selection(base, false)
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # setup_selection
  #--------------------------------------------------------------------------
  def self.setup_selection(base, block = true)
    @close.push(base)
    @selection.push(base) unless @selection.include?(base)
    #---
    directions = [2, 4, 6, 8]
    #---
    directions.each { |d|
      block_cond = check_passable?(@last_battler, base[0], base[1], d)
      non_block  = !block && passable?(base[0], base[1], d)
      if block_cond || non_block
        panel = get_panel(base[0], base[1], d)
        @selection.push(panel) unless @selection.include?(panel)
        temp_1 = @cost[panel[0]][panel[1]]
        temp_2 = @cost[base[0]][base[1]] + 1
        if !@open.include?(panel); 
          @cost[panel[0]][panel[1]] = temp_2
        else
          @cost[panel[0]][panel[1]] = [temp_1, temp_2].min 
        end
        @open.push(panel) unless @close.include?(panel)
      end
    }
    #---
    @open.uniq!
    while @open.size > 0
      o = @open.shift
      if @close.include?(o) || @cost[o[0]][o[1]] >= @max
        @open.delete(o)
        @close.push(o)
      else
        setup_selection(o, block)
      end
    end
  end
    
end # PanelManager