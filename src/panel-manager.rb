# Panel Manager, use to find targetable grids.

#==============================================================================
# Å° PanelManager
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
  # check_last
  #--------------------------------------------------------------------------
  def self.check_last(character, action, base)
    @last_character == character && @last_action == action && 
      @last_position == base
  end
  
  #--------------------------------------------------------------------------
  # check_passable?
  #--------------------------------------------------------------------------
  def self.check_passable?(character, x, y, d)
    return false unless character.passable?(x, y, d)
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
    when 4; return [x - 1, y]
    when 6; return [x + 1, y]
    when 7; return [x - 1, y - 1]
    when 8; return [x    , y - 1]
    when 9; return [x + 1, y - 1]
    end
  end
  
  #--------------------------------------------------------------------------
  # move_selection
  #--------------------------------------------------------------------------
  def self.move_selection(character, fly = false)
    action = fly ? :fly : :move
    base = [character.x, character.y]
    return @selection if check_last(character, action, base)
    @last_character = character
    @last_action = action
    @last_position = base
    #---
    clear
    @cost[base[0]][base[1]] = 0
    @max = character.move_range
    setup_selection(base, character.move_range, !fly)
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # skill_selection
  #--------------------------------------------------------------------------
  def self.skill_selection(character, item)
    base = [character.x, character.y]
    return @selection if check_last(character, item, base)
    @last_character = character
    @last_action = item
    @last_position = base
    #---
    case item.class.name
    when "RPG::Skill"
      range = character.skill_range(item)
    when "RPG::Item"
      range = character.item_range(item)
    end
    clear
    setup_selection(base, range, false)
    #---
    return @selection
  end
  
  #--------------------------------------------------------------------------
  # setup_selection
  #--------------------------------------------------------------------------
  def self.setup_selection(base, range, block = true)
    @close.push(base)
    @selection.push(base) unless @selection.include?(base)
    #---
    directions = [2, 4, 6, 8]
    #---
    directions.each { |d|
      block_cond = check_passable?(@last_character, base[0], base[1], d)
      non_block  = !block && map_bound?(base[0], base[1], d)
      if block_cond || non_block
        panel = get_panel(base[0], base[1], d)
        @selection.push(panel) unless @selection.include?(panel)
        @cost[panel[0]][panel[1]] = @cost[base[0]][base[1]] + 1
        @open.push(panel) unless @close.include?(panel)
      end
    }
    #---
    @open.uniq!
    @open.each { |o|
      if @close.include?(o) || @cost[o[0]][o[1]] && @cost[o[0]][o[1]] == @max
        @open.delete(o)
        @close.push(o)
      else
        setup_selection(o, range - 1, block)
      end
    }
  end
    
end # PanelManager