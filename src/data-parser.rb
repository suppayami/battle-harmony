# Use for parsing database and events by notetag and comment-tag

#==============================================================================
# ¡ö Regular Expression
#==============================================================================

module REGEXP
  module HARMONY
    # Notetags
    SETUP_RANGE = /<(.*) range:[ ]*(\d+)>/i
    CHARSET = /<(?:BATTLER_SET|battler set):[ ]*(.*)>/i
  end
end

#==============================================================================
# ¡ö DataManager
#==============================================================================

module DataManager
  
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_beh load_database; end
  def self.load_database
    load_database_beh
    load_notetags_beh
  end
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_beh
  #--------------------------------------------------------------------------
  def self.load_notetags_beh
    groups = [$data_actors, $data_classes, $data_skills, 
              $data_items, $data_weapons, $data_enemies]
    groups.each { |group|
      group.each { |obj|
        next if obj.nil?
        obj.battle_harmony_initialize
      }
    }
  end
  
end # DataManager

#==============================================================================
# ¡ö RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :harmony_properties
  attr_accessor :character_name 
  attr_accessor :character_index
  
  #--------------------------------------------------------------------------
  # new method: battle_harmony_initialize
  #--------------------------------------------------------------------------
  def battle_harmony_initialize
    create_harmony_default
    create_harmony_data
    create_harmony_sprite
  end
  
  #--------------------------------------------------------------------------
  # new method: create_harmony_default
  #--------------------------------------------------------------------------
  def create_harmony_default
    hash = HARMONY::ENGINE::DEFAULT_PROPERTIES
    @harmony_properties = {}
    #---
    @harmony_properties[:mrange] = hash[:move_range]
    @harmony_properties[:arange] = hash[:attack_range]
    @harmony_properties[:srange] = hash[:skill_range]
    @harmony_properties[:irange] = hash[:item_range]
  end
  
  #--------------------------------------------------------------------------
  # new method: create_harmony_data
  #--------------------------------------------------------------------------
  def create_harmony_data
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when REGEXP::HARMONY::SETUP_RANGE
        property = $1.upcase
        value = $2.to_i
        #---
        case property
        when "MOVE"
          @harmony_properties[:mrange] = value
        when "ATTACK"
          @harmony_properties[:arange] = value
        when "SKILL"
          @harmony_properties[:srange] = value
        when "MOVE"
          @harmony_properties[:irange] = value
        end
      end
    }
  end
  
  #--------------------------------------------------------------------------
  # new method: move_range
  #--------------------------------------------------------------------------
  def move_range
    @harmony_properties[:mrange]
  end
  
  #--------------------------------------------------------------------------
  # new method: attack_range
  #--------------------------------------------------------------------------
  def attack_range
    @harmony_properties[:arange]
  end
  
  #--------------------------------------------------------------------------
  # new method: use_range
  #--------------------------------------------------------------------------
  def use_range
    result = 0
    #---
    case self.class.name
    when "RPG::Weapon"
      result = @harmony_properties[:arange]
    when "RPG::Skill"
      result = @harmony_properties[:srange]
    when "RPG::Item"
      result = @harmony_properties[:irange]
    end
    #---
    result
  end
  
  #--------------------------------------------------------------------------
  # new method: create_harmony_sprite
  #--------------------------------------------------------------------------
  def create_harmony_sprite
    @character_name ||= ""
    @character_index ||= 0
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when REGEXP::HARMONY::CHARSET
        str_scan = $1.scan(/[^,]+/i)
        @character_name = str_scan[0]
        @character_index = str_scan[1].to_i
      end
    }
  end
    
end # RPG::BaseItem