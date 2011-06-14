require 'albino/multi'

class Stinker::Albino < Albino::Multi
  self.bin = ::Albino::Multi.bin
end
