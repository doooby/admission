require_relative '../spec_helper'

RSpec.describe Admission::Index do

  let(:index){ Admission::Index.new }

  def instance_with items=[], children={}
    index = Admission::Index.new
    index.instance_variable_set '@items', items
    index.instance_variable_set '@children', children
    index
  end

  describe '#to_list' do

    it 'empty' do
      expect(instance_with.to_list).to eq([])
    end

    it 'non-nested' do
      index = instance_with [:item1, :item2]
      expect(index.to_list).to eq(
          [:item1, :item2]
      )
    end

    it 'nested one level' do
      index = instance_with [:item1, :item2], {nested: instance_with([:n1])}
      expect(index.to_list).to eq(
          [:item1, :item2, {nested: [:n1]}]
      )
    end

    it 'nested two levels' do
      index = instance_with [:item1, :item2],
          {
              nested1a: instance_with([:n1a]),
              nested1b: instance_with([:n1b, {nested2a: instance_with([:n2a, :n2b])}])
          }
      expect(index.to_list).to eq(
          [:item1, :item2, {nested1a: [:n1a], nested1b: [:n1b, {nested2a: [:n2a, :n2b]}]}]
      )
    end

  end

  describe '#==' do

    it 'compares two instances' do
      instance1 = instance_with
      expect(instance1).not_to receive(:to_list)
      instance2 = instance_with
      expect(instance2).not_to receive(:to_list)

      expect(instance1 == instance2).not_to be_truthy
      expect(instance2 == instance1).not_to be_truthy
      expect(instance1 == instance1).to be_truthy
      expect(instance2 == instance2).to be_truthy
    end

    it 'compares with an array using conversion' do
      instance1 = instance_with [:item1]
      expect(instance1).to receive(:to_list).and_call_original
      expect(instance1 == [:item1]).to be_truthy
    end

    it 'tests rspec eq() delegates to #eql?, i.e. #==' do
      instance1 = instance_with [:item1]
      expect(instance1).to receive(:==).and_call_original
      expect(instance1).to eq([:item1])
    end

  end

  describe '#allow' do

    it 'single' do
      index.allow :single
      expect(index).to eq([:single])
    end

    it 'passed as args' do
      index.allow :single, :double
      expect(index).to eq([:single, :double])
    end

    it 'passed as arrays' do
      index.allow :single, [:a1, :a2], :double, [:b1, :b2]
      expect(index).to eq([:single, :a1, :a2, :double, :b1, :b2])
    end

    it 'convert args to symbols' do
      index.allow 'single', ['a1', 'a2'], 'double', ['b1', 'b2']
      expect(index).to eq([:single, :a1, :a2, :double, :b1, :b2])
    end

    it 'passed as keyword args, nested item' do
      index.allow :single, nested: :a1
      expect(index).to eq([:single, {nested: [:a1]}])
    end

    it 'passed as last position hash' do
      index.allow :single, {nested: :a1}
      expect(index).to eq([:single, {nested: [:a1]}])
    end

    it 'passed as keyword args, nested item list' do
      index.allow :single, nested: [:a1]
      expect(index).to eq([:single, {nested: [:a1]}])
    end

    it 'passed as keyword args, deep nested' do
      index.allow :single, nested: [:a1, {deep_nested: :b1}]
      expect(index).to eq([:single, {nested: [:a1, {deep_nested: [:b1]}]}])
    end

  end

  describe '#include?' do

    it 'looks for an item' do
      index = instance_with [:item1]
      expect(index.include? :item1).to eq(true)
      expect(index.include? :item2).to eq(false)
    end

    it 'looks for a nested item' do
      index = instance_with [], {nested: instance_with([:item2])}
      expect(index.include? :item1).to eq(false)
      expect(index.include? :item2).to eq(false)
      expect(index.include? :nested, :item1).to eq(false)
      expect(index.include? :nested, :item2).to eq(true)
      expect(index.include? :non_nested, :item1).to eq(false)
    end

    it 'converts arguments' do
      index = instance_with [:item1], {nested: instance_with([:item2])}
      expect(index.include? 'item1').to eq(true)
      expect(index.include? 'nested', 'item2').to eq(true)
    end

  end

end