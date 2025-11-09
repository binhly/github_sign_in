Gem::Specification.new do |s|
  s.name     = 'github_sign_in'
  s.version  = '0.1.0'
  s.authors  = ['Binh Ly']
  s.email    = ['binh@happybuild.io']
  s.summary  = 'Sign in (or up) with Github for Rails applications'
  s.homepage = 'https://github.com/your-github-username/github_sign_in'
  s.license  = 'MIT'

  s.required_ruby_version = '>= 2.5.0'

  s.add_dependency 'rails', '>= 6.1.0'
  s.add_dependency 'oauth2', '>= 1.4.0'

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md", "SECURITY.md"]
end
