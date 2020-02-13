require 'sinatra'
require_relative 'round_1'
require_relative 'app'

#\ -p 4567

use Round1
run Root
