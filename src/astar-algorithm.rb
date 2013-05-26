#==============================================================================
# ¡ ANode
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
# ¡ PanelManager
#==============================================================================

module PanelManager
  
  #--------------------------------------------------------------------------
  # Initialize Variables
  #--------------------------------------------------------------------------
  @aopen = []
  @aclose = []
  DIRECTION = [4,8,6,2]
    
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
  def self.findpath(character, p1, p2)
    @aopen.clear
    @aclose.clear
    #---
    p1.g = 0
    p1.h = distance(p2, p1)
    p1.f = p1.h
    #---
    @aopen.push(p1)
    #---
    while @aopen.size > 0
      top = @aopen.shift
      #---
      if top.points == p2.points
        p2.parent = @aclose[@aclose.size - 1]
        return true
      end
      #---
      DIRECTION.each { |i|
        next_point = get_panel(top.points[0], top.points[1], i)
        topConnect = (@aopen + @aclose).select { |i| i.points == next_point }[0]
        topConnect = ANode.new(next_point[0], next_point[1]) if topConnect.nil?
        #---
        if !@aclose.include?(topConnect) && 
          check_passable?(top.points[0], top.points[1], i)
          if !@aopen.include?(topConnect)
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
      #---
      @aclose.push(top)
    end
    #---
    return false
  end
  
end # PanelManager