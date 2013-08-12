#==============================================================================
# ¡ö ANode
#==============================================================================

class ANode
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :parent
  attr_accessor :g
  attr_accessor :h
  attr_accessor :f
  attr_accessor :points
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(x, y)
    @parent = nil
    @g = 0
    @h = 0
    @f = 0
    @points = [x, y]
  end
  
end # ANode

#==============================================================================
# ¡ö PanelManager
#==============================================================================

module PanelManager
  
  #--------------------------------------------------------------------------
  # Initialize Variables
  #--------------------------------------------------------------------------
  @aopen = []
  @aclose = []
  DIRECTION = [2, 4, 6, 8]
    
  #--------------------------------------------------------------------------
  # self.distance
  #--------------------------------------------------------------------------
  def self.distance(node1, node2)
    p1 = node1.points; p2 = node2.points
    ((p1[0] - p2[0]).abs + (p1[1] - p2[1]).abs)
  end
  
  #--------------------------------------------------------------------------
  # self.cost
  #--------------------------------------------------------------------------
  def self.cost(node1, node2)
    p1 = node1.points; p2 = node2.points
    return 0 if p1 == p2
    (p1[0] == p2[0] || p1[1] == p2[1]) ? 1 : 2
  end
  
  #--------------------------------------------------------------------------
  # self.findpath
  #--------------------------------------------------------------------------
  def self.findpath(battler, p1, p2)
    @aopen.clear
    @aclose.clear
    #---
    p1.g = 0
    p1.h = distance(p1, p2)
    p1.f = p1.h
    #---
    @aopen.push(p1)
    #---
    while @aopen.size > 0
      top = @aopen.shift
      @aclose.push(top) if !@aclose.any? { |x| x.points == top.points }
      #---
      if top.points == p2.points
        p2.parent = @aclose.pop
        return true
      end
      #---
      DIRECTION.each { |i|
        next_point = get_panel(top.points[0], top.points[1], i)
        topConnect = (@aopen + @aclose).select { |i| i.points == next_point }[0]
        topConnect = ANode.new(next_point[0], next_point[1]) if topConnect.nil?
        #---
        if !@aclose.any? { |x| x.points == topConnect.points } && 
          check_passable?(battler, top.points[0], top.points[1], i)
          if !@aopen.any? { |x| x.points == topConnect.points }
            topConnect.g = top.g + cost(top, topConnect)
            topConnect.h = distance(p2, topConnect)
            topConnect.f = topConnect.g + topConnect.h
            topConnect.parent = top
            @aopen.push(topConnect)
          else
            tempG = top.g + cost(top, topConnect)
            if tempG < topConnect.g
              topConnect.g = tempG
              topConnect.f = topConnect.g + topConnect.h
              topConnect.parent = top
            end
          end
        end
      }
      #---
      @aopen.sort! { |a,b| a.f <=> b.f }
    end
    #---
    return false
  end
  
  #--------------------------------------------------------------------------
  # self.move_path
  #--------------------------------------------------------------------------
  def self.move_path(final_node)
    path = []
    node = final_node
    nodes = []
    #---
    while node.parent
      node = node.parent
      nodes.push(node.points)
    end
    nodes.shift
    #---
    target_x = final_node.points[0]
    target_y = final_node.points[1]
    #---
    start_x = nodes.reverse[0][0]
    start_y = nodes.reverse[0][1]
    #---
    while nodes.size > 0
      points = nodes.shift
      parent_x = points[0]
      parent_y = points[1]
      if    target_x < parent_x; code = 2
      elsif target_x > parent_x; code = 3
      else; code = target_y < parent_y ? 4 : 1
      end
      path.push(RPG::MoveCommand.new(code))
      target_x = parent_x
      target_y = parent_y
      break if target_x == start_x && target_y == start_y
    end
    return path.reverse + [RPG::MoveCommand.new(0)]
  end
  
  #--------------------------------------------------------------------------
  # self.print_path
  # Use for debug
  #--------------------------------------------------------------------------
  def self.print_path(node)
    return unless HARMONY::ENGINE::DEBUG_ASTAR
    nodes = [node.points]
    while node.parent
      node = node.parent
      nodes.push(node.points)
    end
    nodes.shift
    nodes.reverse.each {|a| print a; print "  "}
  end
  
end # PanelManager