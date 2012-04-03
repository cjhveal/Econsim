require 'graph'

class Agent
  attr_reader :id
  attr_accessor :pref, :prod, :wood, :iron, :gold

  @@id_count = 0
  def initialize (pref=:gold, prod=:wood, wood=0, iron=0, gold=0)
    @id = @@id_count
    @@id_count += 1
    @wood, @iron, @gold = wood, iron, gold
    @pref, @prod = pref, prod
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
  attr_accessor :agents
  PRODUCTION_RATE = 10
  TRADES_PER_DAY = 10
  DAYS_TO_RUN = 10
  RESOURCES = [:wood, :iron, :gold]

  def initialize n
    @agents = []
    n.times do
      pref,prod = RESOURCES.sample 2
      @agents << (Agent.new pref, prod)
    end
  end

  def log_day n
    STDOUT.write "***DAY #{n}***\n"
    @agents.each_with_index do |a,i|
      STDOUT.write "Agent:#{i} (Pref:#{a.pref.to_s}, Prod:#{a.prod.to_s}) | Wood:#{a.wood}, Iron:#{a.iron}, Gold:#{a.gold}\n"
    end
    STDOUT.write '\n'
  end

  def graph_day n, trades
    agents = @agents
    digraph do
      node_attribs << filled << box
      node_attribs << "colorscheme=set14"
      RESOURCES.map {|r| agents.select {|a| a.pref == r}}.each_with_index do |agents, i|
        agents.each_with_index do |a|
          node(a.id.to_s,"#{a.id} (#{a.get_pref})").attributes << "fillcolor=#{i+1}"
        end
      end
      trades.each do |trade|
        a, b = trade
        edge a.id.to_s, b.id.to_s, a.id.to_s
      end
      save "img#{n}", "png"
    end
  end

  def trade a, b
    return false if a.pref == b.pref

    prefs = [a.get_resource(b.pref), b.get_resource(a.pref)]
    return false unless prefs.all? {|x| x > 0} 

    limit = prefs.min
    a.inc_pref limit; a.dec_resource b.pref, limit
    b.inc_pref limit; b.dec_resource a.pref, limit
    [a,b]
  end

  def produce
    @agents.each { |a| a.inc_prod PRODUCTION_RATE }
  end

  def run n=DAYS_TO_RUN
    n.times do |i|
      self.produce
      trades = []
      TRADES_PER_DAY.times do
        a,b = @agents.sample 2
        trades << (self.trade a, b)
      end
      self.graph_day i, trades.select {|t| t}
    end
  end
end

m = Market.new 10
m.run
