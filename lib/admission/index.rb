class Admission::Index

  attr_reader :items, :children

  def initialize
    @items = []
    @children = {}
  end

  def add *add_items, **add_children
    @items |= add_items.flatten.map(&:to_sym)

    add_children.each do |key, list|
      child = @children[key] || Admission::Index.new
      child.add *list
      children[key] = child
    end

    self
  end

  def include? *path
    item, *path = path
    item = item.to_sym

    if path.empty?
      items.include? item

    else
      child = children[item]
      child ? child.include?(*path) : false
    end
  end

  def == other
    case other
      when Array
        to_list.eql? other
      else
        super
    end
  end
  alias :eql? :==

  def to_list
    result_list = items.dup

    unless children.empty?
      result_children = children.inject Hash.new do |h, (key, index)|
        h[key] = index.to_list
        h
      end
      result_list.push result_children
    end

    result_list
  end

end