# coding: utf-8

# The popular game Mörderspiel is played with large number of participants.
# Each player gets assigned a prey (another player) whom he or she has to
# catch. So each player is prey and hunter at the same time.
# The stager has to assure that every player has exactly one prey and
# that each prey has exactly one hunter.
#
# The best case is to have one circle (permutation) of players where every
# player hunts his successor (and the last one hunts the first one).
#
# Such a circle is easy to construct. It gets more difficult if you want to
# include additional constraints:
# - Some of the players know each other and each hunter should go for a
#   prey she does not knod (that does not belong to her group)
# - In some scenarios you want to play in more than one circle simultaniously
#   In this case a hunter shall not have the same prey in different circles
#   (which occours surprisingly often if you create the circles randomly)
#
# This program stages games with three circles which fulfil these constraints

class Player

  # A Player has a name, a group
  # and for each circle predecessors and successors
  # (we could go without explicitely using predecessors
  # but the may come in handy especially for debugging)
  attr_reader :pred, :succ, :name, :group

  # Create a new Player named name.
  # If the group is nil group constraints are ignored
  def initialize(name, group=nil)
    @name = name
    @group = group
    @pred = []
    @succ = []
  end

  # Is p a successor of the player in any circle?
  def succ?(p)
    @succ.include?(p)
  end

  # Is p a predecessor of the player in any circle?
  def pred?(p)
    @pred.include?(p)
  end

  # A short string representantion of the predecessors
  def pred_s
    a_s(@pred)
  end

  # A short string representantion of the successors
  def succ_s
    a_s(@succ)
  end

  # Add p as successor to circle c (and set the backlink)
  def successor(c, p)
    @succ[c] = p
    p.pred[c] = self
  end

  # Find the i-th successor of the player and return it
  def step(c, i)
    if i == 0
      self
    else
      @succ[c].step(c, i-1)
    end
  end

  # Insert p into circle c at the next position fulfilling all constraints
  def insert_next_fitting(c, p)
    if fits_next?(c, p)
      p.successor(c, @succ[c])
      successor(c, p)
    else
      @succ[c].insert_next_fitting(c, p)
    end
  end

  # Test whether p breaks any constraints when inserted between the
  # Player and its current successor q in circle c.
  # Constraints are that the Player may not have p as successor
  # in another circle and that p may not have q as successor in another
  # circle. If the group of p is not nil the Player and its successor q
  # shall both have another group as p. 
  def fits_next?(c, p)
    !succ?(p) && !@succ[c].pred?(p) &&
      (!p.group || ((@group!=p.group) && (@succ[c].group!=p.group)))
  end

  def inspect
    "#<#{self.class} @name=#{@name} @group=#{@group} succ=#{succ_s} pred=#{pred_s}>"
  end

  def to_s
    inspect
  end

  def to_abrv
    "#{@name}/#{@group}"
  end
  
  private
  def a_s(a)
    a.collect { |p|
      if p
        p.to_abrv
      else
        "_"
      end
    }.join(',')
  end
end

# The stager
class Circulator
  attr_reader :players

  # For testing purposes we generate player lists randomly
  # n is the number of players. If ng is nil no groups are assigned to
  # players. If ng is an Integer each player is assigned to one of ng
  # groups randomly. If ng is a list of Integers each number is used as
  # the number of players in the group (you get a warning if the numbers
  # do not sum up to n and n is ignored).
  def self.generate(n, ng=nil)
    case ng
    when Integer
      new((1..n).collect { |i| Player.new("P#{i}", "g#{rand(ng)}") })
    when Enumerable
      nn = ng.inject(:+)
      warn "Wrong n: #{n} != #{nn}" unless n == nn
      new(ng.collect.with_index { |nc,j|
            (1..nc).collect { |i|  Player.new("P#{i}", "g#{j}") }}.flatten)
    else
      new((1..n).collect { |i| Player.new("P#{i}") })
    end
  end

  # Stage a graph for the given list of players
  def initialize(players)

    # we may need preprocessing if players are given as strings
    players = parse(players) unless players.first.kind_of? Player

    # preprocessing the player list to ensure an optimal distribution
    # of groups
    @players = prepare_group_sort(players)

    @starter = @players.first # all our circles start here

    # We prepare the core graph.
    breed(@players)

    # Now we add all the other players step by step
    @players[5..-1].each.with_index do |p,i|
      insert(p, 0, 5+i)
      insert(p, 1, 5+i)
      insert(p, 2, 5+i)
    end
  end

  # To be able to fulfill the grub contraint we need to have the maximum
  # variaty possible at the beginning:
  def prepare_group_sort(players)
    # We put the players in buckets by their groups
    buckets = players.group_by { |p| p.group }.values.sort_by { |a| -a.length }

    # And then we collect them across the buckets
    bucket = buckets.shift
    bucket.zip(*buckets).flatten.compact
  end

  # Prepare the core graph. To be able to have three disjunct
  # Hamilton paths in one Kn you need at least 5 nodes so we
  # hardcode a graph with 5 nodes and three disjunct circles
  def breed(players)
    (0..4).each do |i|
      players[i].successor(0, players[(i + 1) % 5])
      players[i].successor(1, players[(i - 1) % 5])
      players[i].successor(2, players[(i + 2) % 5])
    end
  end

  # To insert a new player in a graph c we randomly choose a starting
  # position and search for the next valid spot to insert the player
  def insert(p, c, n)
    @starter.step(c, rand(n)).insert_next_fitting(c, p)
  end

  # Returns circle c.
  def get_circle(c, l=[@starter])
    p = l.last
    if p.succ[c] == @starter
      l
    else
      get_circle(c, l << p.succ[c])
    end
  end

  # give a short String representation of the circle c.
  def circle_to_s(c)
    get_circle(c).collect { |p| p.to_abrv }.join(',')
  end

  def inspect
    "#<#{self.class} @players=[#{@players.collect{|p|p.to_abrv}.join(',')}]>"
  end

  private
  def parse(players)
    players.collect { |s|
      name,group = s.split('/')
      Player.new(name, group)
    }
  end
end


# usage examples:

puts "=== Circles from given input:"
circ = Circulator.new(%w(A/x B/y C/y D/z E/z F/x G/u H/u I/v J/t K/s L/s))
(0..2).each do |i|
  puts circ.circle_to_s(i)
end

puts "=== Circles from random input (20 players, 9 groups)"

circ = Circulator.generate(20,9)
(0..2).each do |i|
  puts circ.circle_to_s(i)
end

puts "=== Circles from random input (groups with given sizes)"

circ = Circulator.generate(34,[10,8,5,4,3,2,1,1])
(0..2).each do |i|
  puts circ.circle_to_s(i)
end

