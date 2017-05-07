require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"
require "facter"

Puppet::Type.type(:nimble_protection_template).provide(:nimble_protection_template) do
  desc "Work on Nimble Array Volumes"
  mk_resource_methods


  def mergeof_psmeta(obj)
    ret = {}
    ret[:volcoll_or_prottmpl_id] = "#{$pt_id}"
    ret[:volcoll_or_prottmpl_type] = "protection_template"
    ret = ret.merge(JSON.parse(obj.to_json, symbolize_names: true))
    return ret
  end

  def rethash(obj)
    return JSON.parse(obj.to_json, symbolize_name: true)
  end

  def add_schedule(resource, add)
    if !self.schedule_id(resource, add)
      doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/protection_schedules", {"data" => self.mergeof_psmeta(add) },{"X-Auth-Token" => $token})
    else
      self.update(resource, add, add)
    end
  end

  def del_schedule(resource, del)
    id = schedule_id(resource, del)
    begin
      if id != false
        doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/protection_schedules/" + id , {"X-Auth-Token" => $token})
      end
    rescue => e
      e.message
    end
  end

  def update(resource, del, add)
    payload = Hash.new
    payload = self.rethash(Hash(add))
    payload.delete(:name)
    if self.schedule_id(resource, add)
      begin
        doPUT(resource[:transport]['server'], resource[:transport]['port'], "/v1/protection_schedules/" + del['id'], {"data" => payload },{"X-Auth-Token" => $token})
        rescue
      end
    end
  end

  def schedule_id(resource, obj)
    ps_detail = doGET(resource[:transport]['server'], resource[:transport]['port'], "/v1/protection_schedules/detail?name=" + obj['name'].to_s ,  {"X-Auth-Token" => $token})
    if ps_detail['data'].size > 0
      return ps_detail['data'][0]['id']
    else
      return false
    end
  end

  def create
    $token=Facter.value('token')
    protection_template = Hash.new
    protection_template[:name] = resource[:name]
    #requestedParams.delete(:provider)
    #requestedParams.delete(:ensure)
    #requestedParams.delete(:transport)
    #requestedParams.delete(:loglevel)
    #requestedParams.delete(:perfpolicy)
    #requestedParams.delete(:config)
    #requestedParams.delete(:mp)

    pt_details = pt_details_api(resource[:transport], resource[:name])

    if pt_details == nil
      doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/protection_templates", {"data" => {name: resource[:name]}}, {"X-Auth-Token" => $token})
      pt_details = pt_details_api(resource[:transport], resource[:name])
      $pt_id = pt_details['id']
    end

    if resource[:schedule_list].size != 0
      resource[:schedule_list].each do |schedule|
        schedule.each do |k, v|
          key = k.to_s
          if pt_details != nil && pt_details['schedule_list'] != nil
            pt_details['schedule_list'].each do |existing_schedule|
              if existing_schedule[key].to_s != v.to_s
                self.update(resource, existing_schedule, schedule )
              end
            end
          end
        end
        self.add_schedule(resource, schedule)
      end
    end

    if pt_details != nil && pt_details['schedule_list'] != nil
      pt_details['schedule_list'].each do |existing_schedule|
        del = true
        resource[:schedule_list].each do |schedule|
          if existing_schedule['name'].to_s == schedule['name'].to_s
            del = false
          end
        end
        if del == true
          self.del_schedule(resource, existing_schedule)
        end
      end
    end

  end

  def destroy
    $token=Facter.value('token')
    pt_details = pt_details_api(resource[:transport], resource[:name])
    if pt_details != nil
      $pt_id = pt_details['id']
      if pt_details['schedule_list'] != nil
        pt_details['schedule_list'].each do |existing_schedule|
          self.del_schedule(resource, existing_schedule)
        end
      end
      doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/protection_templates/" + $pt_id, {"X-Auth-Token" => $token})
    end
  end

  def exists?
    deleteRequested = false
    if resource[:ensure].to_s == "absent"
      deleteRequested = true
    end
    pt_details = pt_details_api(resource[:transport], resource[:name])
    if pt_details.nil?
      return false
    else
      $pt_id = pt_details['id']
    end
    if pt_details['name'].to_s == resource[:name].to_s && resource[:schedule_list].size != 0
      if pt_details['schedule_list'] == nil && deleteRequested == false
        return false
      end
      if deleteRequested
        return true
      end
    end
    if deleteRequested
      return true
    end
    return false
  end
end
