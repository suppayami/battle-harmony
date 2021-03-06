#==============================================================================
# ■ Spriteset_BattleMap
#==============================================================================

class Spriteset_BattleMap < Spriteset_Map
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    super
    init_camera
  end
  
  #--------------------------------------------------------------------------
  # create_characters
  #--------------------------------------------------------------------------
  def create_characters
    @character_sprites ||= []
    @character_sprites.clear
    #---
    create_map_events
    create_battlers
    clear_panels
    #---
    @map_id = $game_map.map_id
  end
  
  #--------------------------------------------------------------------------
  # create_map_events
  #--------------------------------------------------------------------------
  def create_map_events
    $game_map.events.values.each { |event|
      @character_sprites.push(Sprite_Character.new(@viewport1, event))
    }
  end
  
  #--------------------------------------------------------------------------
  # create_battlers
  #--------------------------------------------------------------------------
  def create_battlers
    # Create Enemy Sprites.
    $game_map.enemy_troop.each { |enemy|
      sprite = Sprite_Character.new(@viewport1, enemy.character)
      @character_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # refresh_actors
  #--------------------------------------------------------------------------
  def refresh_actors
    $game_map.actor_party.each { |actor|
      next if @character_sprites.any? { |c| c.character.battler == actor }
      sprite = Sprite_Character.new(@viewport1, actor.character)
      @character_sprites.push(sprite)
    }
    #---
    @character_sprites.each { |sprite|
      battler = sprite.character.battler
      next if all_battlers.include?(battler)
      @character_sprites.delete(sprite)
      sprite.dispose
    }
  end
      
  #--------------------------------------------------------------------------
  # init_camera
  #--------------------------------------------------------------------------
  def init_camera
    return unless HARMONY::ENGINE::BATTLE_START_CAMERA
    first_place = $game_map.start_locations[0]
    activate_cursor
    move_cursor(first_place[0], first_place[1])
    hide_cursor
  end
  
  #--------------------------------------------------------------------------
  # start_locations
  #--------------------------------------------------------------------------
  def start_locations
    $game_map.start_locations.each { |xy|
      sprite = Sprite_Panel.new(@viewport1)
      sprite.show(:start)
      sprite.moveto(xy[0], xy[1])
      @panel_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # clear_panels
  #--------------------------------------------------------------------------
  def clear_panels
    @panel_sprites ||= []
    @panel_sprites.each { |sprite| sprite.dispose }
    @panel_sprites.clear
    @cursor ||= Sprite_Panel.new(@viewport1)
  end
  
  #--------------------------------------------------------------------------
  # start_move
  #--------------------------------------------------------------------------
  def start_move(battler)
    PanelManager.move_selection(battler, false)
    PanelManager.selection.each { |xy|
      sprite = Sprite_Panel.new(@viewport1)
      sprite.show(:move)
      sprite.moveto(xy[0], xy[1])
      @panel_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # start_item
  #--------------------------------------------------------------------------
  def start_item(battler, item)
    PanelManager.item_selection(battler, item)
    PanelManager.selection.each { |xy|
      sprite = Sprite_Panel.new(@viewport1)
      sprite.show(:move)
      sprite.moveto(xy[0], xy[1])
      @panel_sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    update_panels
  end
  
  #--------------------------------------------------------------------------
  # update_panels
  #--------------------------------------------------------------------------
  def update_panels
    @panel_sprites ||= []
    @panel_sprites.each { |sprite| sprite.update }
    #---
    @cursor.update
    #---
    Sprite_Panel.animate
  end

  #--------------------------------------------------------------------------
  # all_battlers
  #--------------------------------------------------------------------------
  def all_battlers
    $game_map.actor_party + $game_map.enemy_troop
  end
  
  #--------------------------------------------------------------------------
  # battler_sprites
  #--------------------------------------------------------------------------
  def battler_sprites
    @character_sprites.select { |sprite| sprite.character.battler }
  end
  
  #--------------------------------------------------------------------------
  # animation?
  #--------------------------------------------------------------------------
  def animation?
    battler_sprites.any? { |sprite| sprite.animation? }
  end
  
  #--------------------------------------------------------------------------
  # activate_cursor
  #--------------------------------------------------------------------------
  def activate_cursor
    @cursor.show(:cursor)
    @cursor.activate
  end
  
  #--------------------------------------------------------------------------
  # deactivate_cursor
  #--------------------------------------------------------------------------
  def deactivate_cursor
    @cursor.deactivate
  end
  
  #--------------------------------------------------------------------------
  # show_cursor
  #--------------------------------------------------------------------------
  def show_cursor
    @cursor.show(:cursor)
  end
  
  #--------------------------------------------------------------------------
  # hide_cursor
  #--------------------------------------------------------------------------
  def hide_cursor
    @cursor.deactivate.hide
  end
  
  #--------------------------------------------------------------------------
  # cursor_handler
  #--------------------------------------------------------------------------
  def cursor_handler(symbol, method)
    @cursor.set_handler(symbol, method)
  end
  
  #--------------------------------------------------------------------------
  # move_cursor
  #--------------------------------------------------------------------------
  def move_cursor(x, y)
    @cursor.moveto(x, y)
  end
  
  #--------------------------------------------------------------------------
  # move_cursor_smooth
  #--------------------------------------------------------------------------
  def move_cursor_smooth(x, y)
    @cursor.moveto_smooth(x, y)
  end
  
  #--------------------------------------------------------------------------
  # cursor_position
  #--------------------------------------------------------------------------
  def cursor_position
    @cursor.position
  end
  
  #--------------------------------------------------------------------------
  # cursor_screen
  #--------------------------------------------------------------------------
  def cursor_screen
    [@cursor.screen_x, @cursor.screen_y]
  end
  
  #--------------------------------------------------------------------------
  # cursor_moving?
  #--------------------------------------------------------------------------
  def cursor_moving?
    @cursor.is_moving?
  end
  
  #--------------------------------------------------------------------------
  # cursor_active?
  #--------------------------------------------------------------------------
  def cursor_active?
    @cursor.active
  end
    
end # Spriteset_BattleMap