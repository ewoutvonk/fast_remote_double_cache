# ---------------------------------------------------------------------------
# This implements a specialization of the standard Capistrano Git
# deployment scm. The most significant difference between this scm
# and the Git is the way the original repository is queried for the actual
# revision: it uses a variable called remote_repository, instead of just the
# repository variable.
# ---------------------------------------------------------------------------
# This file is distributed under the terms of the MIT license by Le1t0,
# and is copyright (c) 2011 by the same.
# ---------------------------------------------------------------------------
require 'capistrano/recipes/deploy/scm/git'

class Capistrano::Deploy::SCM::IndirectGit < Capistrano::Deploy::SCM::Git
  default_command "git"

  # Getting the actual commit id, in case we were passed a tag
  # or partial sha or something - it will return the sha if you pass a sha, too
  def query_revision(revision)
    remote_repository = variable(:remote_repository)
    raise ArgumentError, "Deploying remote branches is no longer supported.  Specify the remote branch as a local branch for the git repository you're deploying from (ie: '#{revision.gsub('origin/', '')}' rather than '#{revision}')." if revision =~ /^origin\//
    return revision if revision =~ /^[0-9a-f]{40}$/
    command = scm('ls-remote', remote_repository, revision)
    result = yield(command)
    revdata = result.split(/[\t\n]/)
    newrev = nil
    revdata.each_slice(2) do |refs|
      rev, ref = *refs
      if ref.sub(/refs\/.*?\//, '').strip == revision.to_s
        newrev = rev
        break
      end
    end
    raise "Unable to resolve revision for '#{revision}' on repository '#{remote_repository}'." unless newrev =~ /^[0-9a-f]{40}$/
    return newrev
  end

end
