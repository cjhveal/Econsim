require 'graph'

class Agent
  attr_reader :id
  attr_accessor :pref, :prod, :wood, :iron, :gold

  attr_accessor :neighbors

  @@id_count = 0
  def initialize (pref=:gold, prod=:wood, wood=0, iron=0, gold=0)
    @id = @@id_count
    @@id_count += 1
    @wood, @iron, @gold = wood, iron, gold
    @pref, @prod = pref, prod

    @neighbors = []
  end

  def get_resource sym
    self.method(sym).call
  end

  def set_resource sym, x
    self.method(sym.to_s + '=').call sym, x
  end

  def inc_resource sym, x
    self.method(sym.to_s + '=').call (self.get_resource sym) + x
  end

  def dec_resource sym, x
    self.method(sym.to_s + '=').call (self.get_resource sym) - x
  end

  def get_pref
    self.method(@pref).call
  end

  def set_pref x
    self.method(@pref.to_s + '=').call x
  end

  def inc_pref x
    self.method(@pref.to_s + '=').call self.get_pref + x
  end

  def dec_pref x
    self.method(@pref.to_s + '=').call self.get_pref - x
  end

  def get_prod
    self.method(@prod).call
  end

  def set_prod x
    self.method(@prod.to_s + '=').call x
  end

  def inc_prod x
    self.method(@prod.to_s + '=').call self.get_prod + x
  end

  def dec_prod x
    self.method(@prod.to_s + '=').call self.get_prod - x
  end

end

class Market
  attr_accessor :agents, :trades, :day_count
  PRODUCTION_RATE = 10
  TRADES_PER_DAY = 3
  DAYS_TO_RUN = 9
  GRAPH_COLOR_BOUND = 100
  GRAPH_COLORS = 9
  GRAPH_SHAPES = ["rect", "diamond", "ellipse"]
  RESOURCES = [:wood, :iron, :gold]

  #TODO: move current simulation day to instance variable

  def initialize n
    @day_count = 0
    @trades = []
    @agents = []
    n.times do
      pref,prod = RESOURCES.sample 2
      @agents << (Agent.new pref, prod)
    end
    @agents.each do |agent|
      agent.neighbors = @agents.select {|a| a.prod == agent.pref and a.pref == agent.prod}
    end
  end

  def log_day
    STDOUT.write "***DAY #{@day_count}***\n"
    @agents.each_with_index do |a,i|
      STDOUT.write "Agent:#{i} (Pref:#{a.pref.to_s}, Prod:#{a.prod.to_s}) | Wood:#{a.wood}, Iron:#{a.iron}, Gold:#{a.gold}\n"
    end
    STDOUT.write '\n'
  end

  def scale a, n
    pref = a.get_pref
    ratio = (PRODUCTION_RATE*n)/(GRAPH_COLORS-1)
    (a.get_pref/ratio + 1).floor
  end

  def graph_day i, n
    market = self
    all_agents = @agents.sort_by &:get_pref
    trades = @trades
    digraph "Day: #{i} of #{n}" do
      node_attribs << filled
      node_attribs << "colorscheme=reds9"
      RESOURCES.map {|r| all_agents.select {|a| a.pref == r}}.each_with_index do |agents, i|
        agents.each do |a|
          node(a.id.to_s, '').attributes << "shape=#{GRAPH_SHAPES[i]}" << "fillcolor=#{market.scale a, n}"
        end
      end
      all_agents.each do |agent|
        agent.neighbors.each do |a| 
          if trades.include? [agent, a]
            green << (edge agent.id, a.id)
          else
            edge agent.id, a.id
          end
        end
      end
      save "img#{i.to_s}", "png"
    end
  end

  def exchange a, b, x, type=:pref
    a_res, b_res = a.method(type).call, b.method(type).call

    a.inc_resource a_res, x; a.dec_resource b_res, x
    b.inc_resource b_res, x; b.dec_resource a_res, x
  end

  def trade a, b
    return false if a.pref == b.pref

    prefs = [a.get_resource(b.pref), b.get_resource(a.pref)]
    return false unless prefs.all? {|x| x > 0} 

    limit = prefs.min
    self.exchange a, b, limit
    [a,b]
  end

  def produce
    @agents.each { |a| a.inc_prod PRODUCTION_RATE }
  end

  def run n=DAYS_TO_RUN
    end_day = n+@day_count
    n.times do |i|
      @day_count += 1
      self.produce
      @trades = []
      @agents.shuffle.each do |a|
        next if a.neighbors.empty?
        TRADES_PER_DAY.times do
          b = a.neighbors.sample
          @trades << (self.trade a, b)
        end
      end
      self.graph_day @day_count, end_day
    end
  end
end
