# frozen_string_literal: true

# Copyright (c) 2018 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'webmock/minitest'
require 'tmpdir'
require_relative '../fake_home'
require_relative '../test__helper'
require_relative '../../lib/zold/wallets'
require_relative '../../lib/zold/key'
require_relative '../../lib/zold/commands/create'

# CREATE test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
class TestCreate < Zold::Test
  def test_creates_wallet
    FakeHome.new(log: test_log).run do |home|
      wallets = Zold::Wallets.new(home.dir)
      remotes = home.remotes
      copies = home.copies
      id = Zold::Create.new(wallets: wallets, copies: copies, remotes: remotes, log: test_log).run(
        ['create', '--public-key=fixtures/id_rsa.pub']
      )
      wallets.acq(id) do |wallet|
        assert(wallet.balance.zero?)
        assert(
          File.exist?(File.join(dir, "#{wallet.id}#{Zold::Wallet::EXT}")),
          "Wallet file not found: #{wallet.id}#{Zold::Wallet::EXT}"
        )
      end
    end
  end

  def test_creates_wallet_even_if_already_exists
    FakeHome.new(log: test_log).run do |home|
      wallets = Zold::Wallets.new(home.dir)
      remotes = home.remotes
      remotes.add('localhost', 80)
      copies = home.copies
      stub_request(:get, /http:\/\/localhost:80\/wallet\//).to_return(status: 200)
      id = Zold::Create.new(wallets: wallets, copies: copies, remotes: remotes, log: test_log).run(
        ['create', '--public-key=fixtures/id_rsa.pub']
      )
      assert_requested(:get, "http://localhost:80/wallet/#{id}")
    end
  end
end
