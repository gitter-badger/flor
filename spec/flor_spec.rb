
#
# specifying flor
#
# Sun Feb  7 14:27:04 JST 2016
#

require 'spec_helper'


describe Flor do

  describe '.to_djan' do

    before :each do

      @v = {
        'type' => 'car',
        'make/brand' => 'mitsubishi',
        'id' => 2,
        'ok' => true,
        'suppliers,' => [],
        'stuff' => 'nada',
        "'branding'" => 'fail',
        'x' => '4',
        'list' => [],
        'dict' => {}
      }
    end

    it 'quotes symbols that could be mistaken for numbers' do

      expect(Flor.to_djan('123')).to eq('"123"')
      expect(Flor.to_djan('123.456')).to eq('"123.456"')
    end

    it 'turns an object into a djan string' do

      expect(
        Flor.to_djan(@v)
      ).to eq(%{
{ type: car, make/brand: mitsubishi, id: 2, ok: true, "suppliers,": [], stuff: nada, "'branding'": fail, x: "4", list: [], dict: {} }
      }.strip)
    end

    it 'returns a compact form when compact: true' do

      expect(
        Flor.to_djan(@v, compact: true)
      ).to eq(%{
{type:car,make/brand:mitsubishi,id:2,ok:true,"suppliers,":[],stuff:nada,"'branding'":fail,x:"4",list:[],dict:{}}
      }.strip)
    end
  end

  describe '.tstamp' do

    it 'returns the current timestamp' do

      expect(
        Flor.tstamp
      ).to match(
        /\A#{Time.now.utc.year}-\d\d-\d\dT\d\d:\d\d:\d\d.\d{6}Z\z/
      )
    end

    it 'turns a Time instance into a String timestamp' do

      t = Time.utc(2015, 12, 19, 13, 30, 00)

      expect(Flor.tstamp(t)).to eq('2015-12-19T13:30:00.000000Z')
    end

    it 'turns a Time instance into a String timestamp' do

      t = Time.utc(2017, 1, 1, 8, 16, 00)

      expect(Flor.tstamp(t)).to eq('2017-01-01T08:16:00.000000Z')
    end
  end

  describe '.true?' do

    it 'returns true when the argument is true for Flor' do

      expect(Flor.true?(1)).to eq(true)
      expect(Flor.true?(true)).to eq(true)
    end

    it 'returns false when the argument else' do

      expect(Flor.true?(nil)).to eq(false)
      expect(Flor.true?(false)).to eq(false)
    end
  end

  describe '.false?' do

    it 'returns true when the argument is false for Flor' do

      expect(Flor.false?(nil)).to eq(true)
      expect(Flor.false?(false)).to eq(true)
    end

    it 'returns false when the argument else' do

      expect(Flor.false?(1)).to eq(false)
      expect(Flor.false?(true)).to eq(false)
    end
  end

  describe '.is_sub_domain?(d, s)' do

    it 'fails if d is not a domain' do

      expect {
        Flor.is_sub_domain?('.test.x', 'y')
      }.to raise_error(ArgumentError, "not a domain \".test.x\"")
    end

    it 'fails if s is not a domain' do

      expect {
        Flor.is_sub_domain?('test.x', '.test.x.y')
      }.to raise_error(ArgumentError, "not a sub domain \".test.x.y\"")
    end

    it 'returns false if s is not a sub domain of d' do

      expect(Flor.is_sub_domain?('test.x', 'test.y')).to eq(false)
    end

    it 'returns true if it is' do

      expect(Flor.is_sub_domain?('test.x', 'test.x')).to eq(true)
      expect(Flor.is_sub_domain?('test.x', 'test.x.y')).to eq(true)
    end
  end
end

