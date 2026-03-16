# frozen_string_literal: true

require_relative 'lib/legion/extensions/hebbian_assembly/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-hebbian-assembly'
  spec.version       = Legion::Extensions::HebbianAssembly::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Hebbian Assembly'
  spec.description   = "Hebb's Cell Assembly Theory for brain-modeled agentic AI — neurons that fire " \
                       'together wire together, forming emergent assemblies that represent concepts, ' \
                       'enable pattern completion, and support associative recall through ' \
                       'co-activation-driven synaptic strengthening.'
  spec.homepage      = 'https://github.com/LegionIO/lex-hebbian-assembly'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-hebbian-assembly'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-hebbian-assembly'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-hebbian-assembly'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-hebbian-assembly/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-hebbian-assembly.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
