#==============================================================================
# ■ Scene_BattleTactics
#==============================================================================

class Scene_BattleTactics < Scene_Base
  
  #--------------------------------------------------------------------------
  # start
  #--------------------------------------------------------------------------
  def start
    super
    $game_map.refresh
    create_spriteset
    create_all_windows
    BattleManager.method_wait_for_message = method(:wait_for_message)
  end
  
  #--------------------------------------------------------------------------
  # post_start
  #--------------------------------------------------------------------------
  def post_start
    super
    prepare_battle
  end
  
  #--------------------------------------------------------------------------
  # create_spriteset
  #--------------------------------------------------------------------------
  def create_spriteset
    @spriteset = Spriteset_BattleMap.new
    @spriteset.cursor_handler(:ok    , method(:on_place_ok    ))
    @spriteset.cursor_handler(:cancel, method(:on_place_cancel))
  end
  
  #--------------------------------------------------------------------------
  # create_all_windows
  #--------------------------------------------------------------------------
  def create_all_windows
    create_message_window
    create_members_window
    create_status_window
    create_tactical_command_window
    create_actor_command_window
    create_info_viewport
  end
  
  #--------------------------------------------------------------------------
  # create_info_viewport
  #--------------------------------------------------------------------------
  def create_info_viewport
    @info_viewport = Viewport.new
    @info_viewport.rect.y = Graphics.height - @members_window.height
    @info_viewport.rect.height = @members_window.height
    @info_viewport.z = 100
    @members_window.viewport = @info_viewport
    @tactical_command_window.viewport = @info_viewport
    @actor_command_window.viewport = @info_viewport
    @status_window.viewport = @info_viewport
  end
  
  #--------------------------------------------------------------------------
  # create_all_windows
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_Message.new
  end
  
  #--------------------------------------------------------------------------
  # create_members_window
  #--------------------------------------------------------------------------
  def create_members_window
    @members_window = Window_PartyBattlers.new
    #---
    @members_window.set_handler(:ok    , method(:start_place))
    @members_window.set_handler(:cancel, method(:cancel_place))
  end
  
  #--------------------------------------------------------------------------
  # create_status_window
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_StatusTBS.new
  end
  
  #--------------------------------------------------------------------------
  # create_tactical_command_window
  #--------------------------------------------------------------------------
  def create_tactical_command_window
    @tactical_command_window = Window_TacticalCommand.new
    #---
    wx = @members_window.width
    @tactical_command_window.x = wx
    #---
    @tactical_command_window.set_handler(:place, method(:command_place))
    @tactical_command_window.set_handler(:fight, method(:command_fight))
  end
  
  #--------------------------------------------------------------------------
  # create_tactical_command_window
  #--------------------------------------------------------------------------
  def create_actor_command_window
    @actor_command_window = Window_ActorCommandTBS.new
    #---
    wx = @members_window.width
    @actor_command_window.x = wx
    @actor_command_window.set_handler(:move  , method(:command_move))
    @actor_command_window.set_handler(:attack, method(:command_attack))
    @actor_command_window.set_handler(:wait  , method(:command_wait))
    @actor_command_window.set_handler(:cancel, method(:command_actor_cancel))
  end
  
  #--------------------------------------------------------------------------
  # start_place
  #--------------------------------------------------------------------------
  def start_place
    first_place = $game_map.empty_position
    #---
    @spriteset.activate_cursor
    @spriteset.move_cursor(first_place[0], first_place[1])
  end
  
  #--------------------------------------------------------------------------
  # cancel_place
  #--------------------------------------------------------------------------
  def cancel_place
    @tactical_command_window.activate
    @members_window.unselect
  end
  
  #--------------------------------------------------------------------------
  # command_place
  #--------------------------------------------------------------------------
  def command_place
    @members_window.activate.select_last
  end
  
  #--------------------------------------------------------------------------
  # command_fight
  #--------------------------------------------------------------------------
  def command_fight
    BattleManager.tbs_turn_start
    start_battle
  end
    
  #--------------------------------------------------------------------------
  # command_move
  #--------------------------------------------------------------------------
  def command_move
    @spriteset.activate_cursor
    @spriteset.start_move(@subject)
  end
  
  #--------------------------------------------------------------------------
  # command_attack
  #--------------------------------------------------------------------------
  def command_attack
    atk_id = @subject.attack_skill_id
    atk_skill = $data_skills[atk_id]
    #---
    @spriteset.activate_cursor
    @spriteset.start_item(@subject, atk_skill)
    #---
    @subject.input.set_attack
  end
  
  #--------------------------------------------------------------------------
  # command_wait
  #--------------------------------------------------------------------------
  def command_wait
    @spriteset.hide_cursor
    @subject = nil
  end
  
  #--------------------------------------------------------------------------
  # command_actor_cancel
  #--------------------------------------------------------------------------
  def command_actor_cancel
    if @subject.returnable?
      @subject.return_position
      @actor_command_window.activate.refresh
      @spriteset.move_cursor(@subject.x, @subject.y)
    end
  end
  
  #--------------------------------------------------------------------------
  # terminate
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_spriteset
    $game_temp.restore_map
  end
  
  #--------------------------------------------------------------------------
  # dispose_spriteset
  #--------------------------------------------------------------------------
  def dispose_spriteset
    @spriteset.dispose
  end
    
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    update_viewport
    update_subject
    update_status
  end
  
  #--------------------------------------------------------------------------
  # update_basic
  #--------------------------------------------------------------------------
  def update_basic
    super
    $game_map.update(true)
    $game_timer.update
    @spriteset.update
  end
    
  #--------------------------------------------------------------------------
  # update_for_wait
  #--------------------------------------------------------------------------
  def update_for_wait
    update_basic
  end
  
  #--------------------------------------------------------------------------
  # wait_for_message
  #--------------------------------------------------------------------------
  def wait_for_message
    @message_window.update
    update_for_wait while $game_message.visible
  end
  
  #--------------------------------------------------------------------------
  # wait_for_camera
  #--------------------------------------------------------------------------
  def wait_for_camera
    update_for_wait
    update_for_wait while camera_moving?
  end
  
  #--------------------------------------------------------------------------
  # wait_for_animation
  #--------------------------------------------------------------------------
  def wait_for_animation
    update_for_wait
    update_for_wait while @spriteset.animation?
  end
  
  #--------------------------------------------------------------------------
  # camera_moving?
  #--------------------------------------------------------------------------
  def camera_moving?
    @spriteset.cursor_moving? || @subject && @subject.is_moving?
  end
  
  #--------------------------------------------------------------------------
  # refresh_status
  #--------------------------------------------------------------------------
  def refresh_status
    @status_window.refresh
  end
  
  #--------------------------------------------------------------------------
  # prepare_battle
  #--------------------------------------------------------------------------
  def prepare_battle
    BattleManager.tbs_start
    start_locations
  end
  
  #--------------------------------------------------------------------------
  # start_locations
  #--------------------------------------------------------------------------
  def start_locations
    @spriteset.start_locations
    @members_window.open
    @tactical_command_window.open.activate
  end
  
  #--------------------------------------------------------------------------
  # start_battle
  #--------------------------------------------------------------------------
  def start_battle
    @spriteset.clear_panels
    @members_window.close
    @tactical_command_window.close
    @status_window.open
  end
  
  #--------------------------------------------------------------------------
  # setup_active_battler
  #--------------------------------------------------------------------------
  def setup_active_battler
    @subject = BattleManager.get_active_battler
    return unless @subject
    @subject.make_actions
    @status_window.subject = @subject
    @spriteset.show_cursor
    @spriteset.move_cursor_smooth(@subject.x, @subject.y)
    #---
    wait_for_camera
    #---
    if @subject.actor?
      @actor_command_window.setup(@subject)
    end
  end
  
  #--------------------------------------------------------------------------
  # update_viewport
  #--------------------------------------------------------------------------
  def update_viewport
    center_x = Graphics.width / 2 + 64
    center_y = Graphics.height / 2 + 64
    #---
    cursor_x = @spriteset.cursor_screen[0]
    cursor_y = @spriteset.cursor_screen[1]
    #---
    if cursor_y > center_y
      @info_viewport.rect.y = 0 
    else
      @info_viewport.rect.y = Graphics.height - @members_window.height
    end
  end
  
  #--------------------------------------------------------------------------
  # update_subject
  #--------------------------------------------------------------------------
  def update_subject
    @subject = nil if @subject && @subject.dead?
    return if @subject
    return unless BattleManager.in_turn?
    setup_active_battler
  end
  
  #--------------------------------------------------------------------------
  # update_status
  #--------------------------------------------------------------------------
  def update_status
    position = @spriteset.cursor_position
    return unless @status_window
    return unless @spriteset.cursor_active?
    battler = $game_map.battler_xy(position[0], position[1])
    @status_window.target = battler
  end
  
  #--------------------------------------------------------------------------
  # on_place_ok
  #--------------------------------------------------------------------------
  def on_place_ok
    case BattleManager.phase
    when :init
      on_init_position_ok
    when :turn
      on_turn_position_ok
    end
  end
  
  #--------------------------------------------------------------------------
  # on_place_cancel
  #--------------------------------------------------------------------------
  def on_place_cancel
    @spriteset.hide_cursor
    case BattleManager.phase
    when :init
      on_init_position_cancel
    when :turn
      on_turn_position_cancel
    end
  end
  
  #--------------------------------------------------------------------------
  # on_init_position_ok
  #--------------------------------------------------------------------------
  def on_init_position_ok
    case @tactical_command_window.current_symbol
    when :place
      place_actor_init
    end
  end
  
  #--------------------------------------------------------------------------
  # place_actor_init
  #--------------------------------------------------------------------------
  def place_actor_init
    actor = @members_window.actor
    position = @spriteset.cursor_position
    if $game_map.start_locations.include?(position)
      $game_map.add_actor(actor, position)
      @spriteset.refresh_actors
      @spriteset.hide_cursor
      @tactical_command_window.refresh
      check_max_actor
    else
      @spriteset.activate_cursor
    end
  end
  
  #--------------------------------------------------------------------------
  # check_max_actor
  #--------------------------------------------------------------------------
  def check_max_actor
    if $game_map.max_actor?
      @tactical_command_window.select_fight
      @tactical_command_window.activate
      @members_window.refresh
      @members_window.unselect
    else
      @members_window.activate.refresh
      @members_window.select_next
    end
  end
  
  #--------------------------------------------------------------------------
  # on_turn_position_ok
  #--------------------------------------------------------------------------
  def on_turn_position_ok
    case @actor_command_window.current_symbol
    when :move
      move_actor
    else
      item_actor
    end
  end
  
  #--------------------------------------------------------------------------
  # move_actor
  #--------------------------------------------------------------------------
  def move_actor
    position = @spriteset.cursor_position
    if PanelManager.selection.include?(position)
      @subject.camera_follow(true)
      @subject.moveto(position[0], position[1])
      wait_for_camera
      @subject.camera_follow(false)
      #---
      @spriteset.clear_panels
      @actor_command_window.activate.refresh
    else
      @spriteset.activate_cursor
    end
  end
  
  #--------------------------------------------------------------------------
  # item_actor
  #--------------------------------------------------------------------------
  def item_actor
    position = @spriteset.cursor_position
    if PanelManager.selection.include?(position)
      # Need fix
      @subject.input.target_index = $game_map.battler_xy(position[0], position[1]).index
      execute_action
      # End Need fix
      @subject.end_action
      @spriteset.clear_panels
      @actor_command_window.activate.refresh
    else
      @spriteset.activate_cursor
    end
  end
  
  #--------------------------------------------------------------------------
  # on_init_position_cancel
  #--------------------------------------------------------------------------
  def on_init_position_cancel
    @tactical_command_window.open
    @members_window.open.activate
  end
  
  #--------------------------------------------------------------------------
  # on_turn_position_cancel
  #--------------------------------------------------------------------------
  def on_turn_position_cancel
    @spriteset.clear_panels
    @spriteset.show_cursor
    @spriteset.move_cursor(@subject.x, @subject.y)
    @actor_command_window.activate
  end
  
  #--------------------------------------------------------------------------
  # execute_action
  #--------------------------------------------------------------------------
  def execute_action
    item = @subject.current_action.item
    @subject.use_item(item)
    refresh_status
    targets = @subject.current_action.make_targets.compact
    show_animation(targets, item.animation_id)
    targets.each {|target| item.repeats.times { invoke_item(target, item) } }
  end
  
  #--------------------------------------------------------------------------
  # invoke_item
  #--------------------------------------------------------------------------
  def invoke_item(target, item)
    apply_item_effects(target, item)
    @subject.last_target_index = target.index
  end
  
  #--------------------------------------------------------------------------
  # apply_item_effects
  #--------------------------------------------------------------------------
  def apply_item_effects(target, item)
    target.item_apply(@subject, item)
    refresh_status
  end
  
  #--------------------------------------------------------------------------
  # show_animation
  #--------------------------------------------------------------------------
  def show_animation(targets, animation_id)
    if animation_id < 0
      show_attack_animation(targets)
    else
      show_normal_animation(targets, animation_id)
    end
    wait_for_animation
  end
  
  #--------------------------------------------------------------------------
  # show_attack_animation
  #--------------------------------------------------------------------------
  def show_attack_animation(targets)
    show_normal_animation(targets, @subject.atk_animation_id1, false)
    wait_for_animation
    show_normal_animation(targets, @subject.atk_animation_id2, true)
  end
  
  #--------------------------------------------------------------------------
  # show_normal_animation
  #--------------------------------------------------------------------------
  def show_normal_animation(targets, animation_id, mirror = false)
    animation = $data_animations[animation_id]
    if animation
      targets.each do |target|
        target.animation_id = animation_id
        target.animation_mirror = mirror
      end
    end
  end
  
end # Scene_BattleTactics