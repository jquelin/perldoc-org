package Perldoc::Convert::html;

use strict;
use warnings;
use Perldoc::Function;
use Perldoc::Syntax;
use Pod::Escapes qw/e2char/;
use Pod::ParseLink;
use Pod::POM;
use Pod::POM::View::HTML;
use Pod::POM::View::Text;

use Data::Dumper;

our @ISA = qw/Pod::POM::View::HTML/;
our $document_name;
our @OVER;


#--------------------------------------------------------------------------

sub convert {
  local $document_name = shift;
  my $pod    = shift;
  my $parser = Pod::POM->new();
  my $pom    = $parser->parse_text($pod);
  my $index  = build_index($pom);
  my $body   = Perldoc::Convert::html->print($pom);
  return $index."<!--  [% TAGS [~ ~] %]  -->\n$body";
}


#--------------------------------------------------------------------------

sub build_index {
  my $pod   = shift;
  my $index = '';
  if ($pod->head1->[0]) {
    $index .= '<ul>';
    foreach my $head1 ($pod->head1) {
      my $title  = $head1->title->present(__PACKAGE__);
      my $anchor = escape($head1->title->present('Pod::POM::View::Text'));
      $index   .= qq{<li><a href="#$anchor">$title</a>};
      if ($head1->head2->[0]) {
        $index .= '<ul>';
          foreach my $head2 ($head1->head2) {
            $title  = $head2->title->present(__PACKAGE__);
            $anchor = escape($head2->title->present('Pod::POM::View::Text'));
            $index .= qq{<li><a href="#$anchor">$title</a>};
          }
        $index .= '</ul>';
      }
    }
    $index .= '</ul>';
  }
  return $index;
}


#--------------------------------------------------------------------------

sub view_pod {
  my ($self,$pod) = @_;
  return $pod->content->present($self);
}


#--------------------------------------------------------------------------

sub view_for {
  my ($self,$for) = @_;
  if ($for->format eq 'text') {
    return '<pre>'.$for->text.'</pre>';
  }
  if ($for->format eq 'html') {
    return $for->text;
  }
  return '';
}


#--------------------------------------------------------------------------

sub view_begin {
  my ($self,$begin) = @_;
  #warn Dumper($begin);
  if ($begin->format eq 'text') {
    return '<pre>'.$begin->content->present($self).'</pre>';
  }
  if ($begin->format eq 'html') {
    $Pod::POM::View::HTML::HTML_PROTECT++;
    my $output = $begin->content->present($self);
    $Pod::POM::View::HTML::HTML_PROTECT--;
    return $output;
  }
  return '';
}


#--------------------------------------------------------------------------

sub view_head1 {
  my ($self,$head1) = @_;
  my $title = $head1->title->present($self);
  my $anchor = escape($head1->title->present('Pod::POM::View::Text'));
  return qq{<a name="$anchor"></a><h1>$title</h1>\n}.
         $head1->content->present($self);
}


#--------------------------------------------------------------------------

sub view_head2 {
  my ($self,$head2) = @_;
  my $title = $head2->title->present($self);
  my $anchor = escape($head2->title->present('Pod::POM::View::Text'));
  return qq{<a name="$anchor"></a><h2>$title</h2>\n}.
         $head2->content->present($self);
}


#--------------------------------------------------------------------------

sub view_over {
  my ($self, $over) = @_;
  my ($start, $end, $strip);
  my $items = $over->item();
  return "" unless @$items;
  my $first_title = $items->[0]->title();
  if ($first_title =~ /^\s*\*\s*/) {
    # '=item *' => <ul>
    $start = "<ul>\n";
    $end   = "</ul>\n";
    $strip = qr/^\s*\*\s*/;
  } elsif ($first_title =~ /^\s*\d+\.?\s*/) {
    # '=item 1.' or '=item 1 ' => <ol>
    $start = "<ol>\n";
    $end   = "</ol>\n";
    $strip = qr/^\s*\d+\.?\s*/;
  } else {
    $start = "<ul>\n";
    $end   = "</ul>\n";
    $strip = '';
  }
  
  my $overstack = ref $self ? $self->{ OVER } : \@OVER;
  push(@$overstack, $strip);
  my $content = $over->content->present($self);
  pop(@$overstack);
  
  return $start . $content . $end;
}


#--------------------------------------------------------------------------

sub view_item {
  my ($self,$item) = @_;
  my $over  = ref $self ? $self->{ OVER } : \@OVER;
  my $title = $item->title();
  my $strip = $over->[-1];
  if (defined $title) {
    $title = $title->present($self) if ref $title;
    $title =~ s/$strip// if $strip;
    if (length $title) {
      my $anchor = escape($item->title->present('Pod::POM::View::Text'));
      $title = qq{<a name="$anchor"></a><b>$title</b>};
    }
  }
  return '<li>'."$title\n".$item->content->present($self)."</li>\n";
}


#--------------------------------------------------------------------------

sub view_verbatim {
  my ($self,$text) = @_;
  #$text =~ s/&/&amp;/sg;
  #$text =~ s/</&lt;/sg;
  #$text =~ s/>/&gt;/sg;
  #$text = Perldoc::Syntax::highlight();
  #return qq{<pre class="verbatim">$text</pre>};
  my $linkpath = '../' x (0 + $document_name =~ s/::/::/g);
  return Perldoc::Syntax::highlight('<pre class="verbatim">','</pre>',$text,$linkpath);
}


#--------------------------------------------------------------------------

sub view_seq_code {
  my ($self,$text) = @_;
  
  #$text =~ s/&/&amp;/sg;
  #$text =~ s/</&lt;/sg;
  #$text =~ s/>/&gt;/sg;
  #return qq{<code class="inline">$text</code>};
  
  $text =~ s/&gt;/>/sg;
  $text =~ s/&lt;/</sg;
  $text =~ s/&amp;/&/sg;

  my $linkpath = '../' x (0 + $document_name =~ s/::/::/g);
  #my $ntext = Perldoc::Syntax::highlight('<code class="inline">','</code>',$text,$linkpath);
  #warn "$document_name: input = $text, output = $ntext\n";
  return Perldoc::Syntax::highlight('<code class="inline">','</code>',$text,$linkpath);
  #return $ntext;
}


#--------------------------------------------------------------------------

sub view_seq_link {
  my ($self, $link) = @_;
  # view_seq_text has already taken care of L<http://example.com/>
  if ($link =~ /^<a href=/ ) {
    return $link;
  }
  
  my ($text,$inferred,$page,$section,$type) = parselink($link);
  #warn "$link at $document_name\n" if ($link =~ /perlvar\//);
  #warn "Link type: $type, link page: $page, link section: $section\n";
  if ($type eq 'pod') {
    my $href;
    if ($page && $section && $page eq 'perlfunc') {
      (my $function = $section) =~ s/(-?[a-z]+).*/$1/i;
      if (Perldoc::Function::exists($function)) {
        $href = '[~ path ~]'."functions/$function.html";
        return qq{<a href="$href">$section</a>};
      } else {
        $section = escape($section);
        $href = '[~ path ~]'."perlfunc.html#$section";
        #warn("Missing function '$function' in link '$link' from page '$document_name', using $href\n");
        return qq{<a href="$href">$inferred</a>};
      }
    }
    if ($page) {
      if (Perldoc::Page::exists($page)) {
        $href = '[~ path ~]'."$page.html";
        $href =~ s/::/\//g;
      } elsif (Perldoc::Function::exists($page)) {
        $href = '[~ path ~]'."functions/$page.html";
        return qq{<a href="$href">$page</a>};      
      } else {
        $href = "http://search.cpan.org/perldoc/$page";
      }        
    }
    if ($section && $document_name eq 'function' and (!$page or $page eq '')) {
      (my $function = $section) =~ s/(-?[a-z]+).*/$1/i;
      if (Perldoc::Function::exists($function)) {
        $href = "$function.html";
        return qq{<a href="$href">$section</a>};
      } else {
        $section = escape($section);
        $href = "../perlfunc.html#$section";
        #warn("Missing function '$function' in link '$link' from page '$document_name', using $href\n");
        return qq{<a href="$href">$inferred</a>};
      }      
    }
    if ($section) {
      $href .= '#'.escape($section);
    }
    return Pod::POM::View::HTML::make_href($href, $inferred);
  } elsif ($type eq 'man') {
    return qq{<i>$inferred</i>};
  } elsif ($type eq 'url') {
    return qq{<a href="$page">$inferred</a>};
  }
}


#--------------------------------------------------------------------------

sub _view_seq_link {
  my ($self, $link) = @_;
  warn "$link\n";
  # view_seq_text has already taken care of L<http://example.com/>
  if ($link =~ /^<a href=/ ) {
    return $link;
  }
  
  # full-blown URL's are emitted as-is
  if ($link =~ m{^\w+://}s ) {
    return Pod::POM::View::HTML::make_href($link);
  }
  
  $link =~ s/\n/ /g;   # undo line-wrapped tags
  my $orig_link = $link;
  my $linktext;
  
  # strip the sub-title and the following '|' char
  if ( $link =~ s/^ ([^|]+) \| //x ) {
    $linktext = $1;
    #warn "$link >> $linktext\n";
  }
  
  # make sure sections start with a /
  $link =~ s|^"|/"|;
  my $page;
  my $section;
  if ($link =~ m|^ (.*?) / "? (.*?) "? $|x) { 
    # [name]/"section"
    ($page, $section) = ($1, $2);
  } elsif ($link =~ /\s/) {  
    # this must be a section with missing quotes
    ($page, $section) = ('', $link);
  } else {
    ($page, $section) = ($link, '');
  }
  
  # warning; show some text.
  $linktext = $orig_link unless defined $linktext;
  my $url = '';
  if (defined $page && length $page) {
    #$url = $self->view_seq_link_transform_path($page);
    if (Perldoc::Page::exists($page)) {
      $url = "$page.html";
      $url =~ s/::/\//g;
    } else {
      $url = "http://search.cpan.org/perldoc/$page";
    }
  }
  
  # append the #section if exists
  $url .= "#".escape($section) if defined $url and defined $section and length $section;
  return Pod::POM::View::HTML::make_href($url, $linktext);
}


#--------------------------------------------------------------------------

sub view_seq_entity {
  my ($self, $entity) = @_;
  my $text = e2char($entity);
  #warn("$text found in E<$entity> sequence at $document_name\n");
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  return $text;
}


#--------------------------------------------------------------------------

sub view_seq_index {
  my ($self, $entity) = @_;
  return '';  
}


#--------------------------------------------------------------------------

sub view_seq_space {
    my ($self, $text) = @_;
    #$text =~ s/\s/&nbsp;/g;
    return $text;
}


#--------------------------------------------------------------------------

sub escape {
  my $text = shift;
  $text =~ s/^\s*(.*?)\s*$/$1/;
  #$text =~ s/([^a-z0-9])/sprintf("%%%2.2x",ord $1)/ieg;
  $text =~ s/\n/ /g;
  $text =~ tr/ /-/;
  $text =~ s/([^\w()'*~!.-])/sprintf '%%%02x', ord $1/eg;
  return $text;
}


#--------------------------------------------------------------------------

package Pod::POM::View::Text;

sub view_seq_index {
  my ($self, $entity) = @_;
  return '';  
}


1;
