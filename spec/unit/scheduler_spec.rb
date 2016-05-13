
#
# specifying flor
#
# Wed May  4 15:59:30 JST 2016
# Golden Week
#

require 'spec_helper'


describe 'Flor unit' do

  before :each do

    @unit = Flor::Unit.new('.flor-test.conf')
    @unit.conf['unit'] = 'u'
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.stop
    @unit.storage.clear
    @unit.shutdown
  end

  describe Flor::Scheduler do

    describe '#stop' do

      it 'stops' do

        expect(@unit.running?).to eq(true)
        expect(@unit.stopped?).to eq(false)

        @unit.stop

        expect(@unit.running?).to eq(false)
        expect(@unit.stopped?).to eq(true)
      end
    end

    describe '#launch' do

      it 'stores launch messages' do

        @unit.stop

        flon = %{
          sequence
            define sum a, b
              +
                a
                b
            sum 1 2
        }

        exid = @unit.launch(flon)

        expect(
          exid
        ).to match(
          /\Atest-u-#{Time.now.year}\d{4}\.\d{4}\.[a-z]+\z/
        )

        ms = @unit.storage.db[:flon_messages].all
        m = ms.first

        expect(ms.size).to eq(1)
        expect(m[:exid]).to eq(exid)
        expect(m[:point]).to eq('execute')
        expect(JSON.parse(m[:content])['exid']).to eq(exid)
      end
    end

    it 'runs a simple flow' do

        flon = %{
          sequence
            define sum a, b
              +
                a
                b
            sum 1 2
        }

        msg = @unit.launch(flon, wait: true)

        expect(msg.class).to eq(Hash)
        expect(msg['point']).to eq('terminated')
        expect(msg['payload']['ret']).to eq(3)
    end
  end
end

