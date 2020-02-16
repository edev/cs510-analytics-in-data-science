require 'sinatra'
require_relative 'round_1'
require_relative 'round_2'
require_relative 'app'

#\ -o 0.0.0.0 -p 4567

use Round1
use Round2
run Root
