
#
# specifying flor
#
# Sat Jun 18 16:43:30 JST 2016
#

require 'spec_helper'


describe Flor::Loader do

  before :each do

    unit = OpenStruct.new(conf: { 'lod_path' => 'envs/uspec_loader' })
      # force a specific file hieararchy root on the loader via 'lod_path'

    @loader = Flor::Loader.new(unit)
  end

  describe '#variables' do

    it 'loads variables' do

      n = @loader.variables('net')

      expect(n['car']).to eq('fiat')

      ne = @loader.variables('net.example')

      expect(ne['car']).to eq('alfa romeo')
      expect(ne['flower']).to eq('rose')

      oe = @loader.variables('org.example')

      expect(oe['car']).to eq(nil)
      expect(oe['flower']).to eq('lilly')

      nea = @loader.variables('net.example.alpha')

      expect(nea['car']).to eq('lancia')
      expect(nea['flower']).to eq('forget-me-not')
    end
  end

  describe '#library' do

    it 'loads a lib' do

      pa, fn = @loader.library('net.example', 'flow1')

      expect(
        pa
      ).to eq(
        'envs/uspec_loader/usr/net.example/lib/flows/flow1.flo'
      )

      expect(
        fn.strip
      ).to eq(%{
        task 'alice'
      }.strip)

      pa, fn = @loader.library('org.example.flow1')

      expect(
        fn.strip
      ).to eq(%{
        task 'oskar'
      }.strip)
    end
  end

  describe '#tasker' do

    it 'loads a tasker configuration' do

      t = @loader.tasker('', 'alice')

      expect(t['description']).to eq('basic alice')
      expect(t.keys).to eq(%w[ description a _path ])

      t = @loader.tasker('net.example', 'alice')

      expect(t['description']).to eq('basic alice')
      expect(t.keys).to eq(%w[ description a _path ])

      t = @loader.tasker('org.example', 'alice')

      expect(t['description']).to eq('org.example alice')
      expect(t.keys).to eq(%w[ description ao _path ])

      t = @loader.tasker('', 'bob')

      expect(t).to eq(nil)

      t = @loader.tasker('net.example', 'bob')

      expect(t['description']).to eq('usr net.example bob')
      expect(t.keys).to eq(%w[ description ubn _path ])

      t = @loader.tasker('org.example', 'bob')

      expect(t['description']).to eq('org.example bob')
      expect(t.keys).to eq(%w[ description bo _path ])

      t = @loader.tasker('org.example.bob')

      expect(t['description']).to eq('org.example bob')
      expect(t.keys).to eq(%w[ description bo _path ])
    end

    it 'loads a domain tasker configuration' do

      tc = @loader.tasker('com.example.tasker')
      expect(tc['description']).to eq('/cet/dot.json')

      tc = @loader.tasker('com.example', 'tasker')
      expect(tc['description']).to eq('/cet/dot.json')

      tc = @loader.tasker('com.example.alpha.tasker')
      expect(tc['description']).to eq('usr/ceat/dot.json')

      tc = @loader.tasker('com.example.alpha', 'tasker')
      expect(tc['description']).to eq('usr/ceat/dot.json')

      tc = @loader.tasker('com.example.bravo.tasker')
      expect(tc['description']).to eq('usr/cebt/flor.json')

      tc = @loader.tasker('com.example.bravo', 'tasker')
      expect(tc['description']).to eq('usr/cebt/flor.json')
    end

    it 'load a tasker configuration {name}.json' do

      tc = @loader.tasker('org.example', 'charly')
      expect(tc['description']).to eq('org.example charly')
    end
  end
end

